import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../apps/mobile/lib/src/game/application/match_session.dart';
import '../../../apps/mobile/lib/src/game/domain/ai/seeded_ludo_ai.dart';
import '../../../apps/mobile/lib/src/game/domain/ludo_game.dart';
import '../../../apps/mobile/lib/src/game/domain/match_configuration.dart';
import '../../../apps/mobile/lib/src/game/domain/mode_registry.dart';

final http = HttpClient()..connectionTimeout = const Duration(seconds: 5);
final entropy = Random.secure();
final uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

Future<dynamic> api(String path, {Map<String, String>? query, Object? body, String? token}) async {
  final env = Platform.environment;
  final uri = Uri.parse('${env['SUPABASE_URL']}/$path').replace(queryParameters: query);
  final request = await http.openUrl(body == null ? 'GET' : 'POST', uri);
  request.headers.set('apikey', env['SUPABASE_SERVICE_ROLE_KEY']!);
  request.headers.set('Authorization', token ?? 'Bearer ${env['SUPABASE_SERVICE_ROLE_KEY']}');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final content = await utf8.decoder.bind(response).join();
  if (response.statusCode >= 300) throw StateError('Request rejected');
  return jsonDecode(content);
}

Future<Object> turn(HttpRequest req) async {
  final action = req.uri.pathSegments.last;
  if (!['roll_dice','execute_move','handle_turn_timeout'].contains(action) || req.method != 'POST') {
    throw const FormatException();
  }
  final auth = req.headers.value('Authorization');
  if (auth == null || !auth.startsWith('Bearer ')) throw const FormatException();
  final uid = (await api('auth/v1/user', token: auth))['id'] as String;
  final bytes = <int>[];
  await for (final chunk in req) {
    if (chunk.length + bytes.length > 2048) throw const FormatException();
    bytes.addAll(chunk);
  }
  final input = jsonDecode(utf8.decode(bytes)) as Map<String,dynamic>;
  return applyIntent(input, action, uid, auth);
}

Future<Object> applyIntent(Map<String, dynamic> input, String action, String uid, String? auth) async {
  final id = input['match_id'] as String;
  final cmd = input['command_id'] as String;
  final seq = input['expected_sequence'] as int;
  if (!uuid.hasMatch(id) || !uuid.hasMatch(cmd) || seq < 0) throw const FormatException();
  // Read using the participant JWT so the membership policies also apply here.
  final room = (await api('rest/v1/matches', query: {'id':'eq.$id','select':'*,match_players(*)'},token: auth) as List).single;
  final seats = (room['match_players'] as List)..sort((a,b) => (a['seat'] as int).compareTo(b['seat']));
  final receipt = await api('rest/v1/match_events', query: {'match_id':'eq.$id','command_id':'eq.$cmd','select':'actor_key,action,sequence_number,payload'}, token:auth) as List;
  if (receipt.isNotEmpty) {
    final saved = receipt.single;
    if (saved['actor_key'] != uid || saved['action'] != action) throw StateError('Command conflict');
    return {'sequence_number':saved['sequence_number'],'events':saved['payload']};
  }
  if (room['status'] != 'playing' || room['sequence_number'] != seq) throw StateError('Refresh snapshot');
  final initial = room['snapshot'] == null
      ? ModeRegistry.create(MatchMode.values.byName(room['mode']), playerCount:room['capacity'])
      : LudoGame.fromSnapshot(room['snapshot']);
  final colors = initial.configuration.activePlayers;
  final index = colors.indexOf(initial.activePlayer);
  final timeout = action == 'handle_turn_timeout';
  if (!timeout && (seats[index]['player_id'] != uid || seats[index]['bot'] == true)) throw StateError('Wrong seat');
  var session = MatchSession(matchId:id,game:initial,actorIds:{
    for (var i=0;i<colors.length;i++) colors[i]: 'seat-$i',
  });
  final events = <Map<String,Object?>>[];
  void apply(MatchCommand command) {
    final before = session.game;
    final result = session.execute(command);
    if (!result.accepted) throw StateError('Rejected move');
    session = result.session;
    for (final e in result.events) {
      if (e is PawnCaptured) {
        final progress = before.players.firstWhere((p)=>p.color==e.victim).pawnProgress[e.pawnIndex];
        events.add({'type':'capture','color':e.victim.name,'pawn':e.pawnIndex,
          'route_progress':[for(var i=progress;i>=-1;i--) i]});
      } else if (e is PawnMoved) {
        events.add({'type':'move','color':e.player.name,'pawn':e.pawnIndex,'from':e.from,'to':e.to});
      } else if (e is ExtraTurnGranted) {
        events.add({'type':'extra_turn','color':e.player.name});
      }
    }
  }
  final actor = 'seat-$index';
  if (action == 'roll_dice' || (timeout && initial.diceValue == null)) {
    final roll = 1 + entropy.nextInt(6);
    apply(RollDiceCommand(matchId:id,actorId:actor,expectedStateVersion:session.game.stateVersion,commandId:'$cmd:roll',value:roll));
    events.insert(0,{'type':'roll','value':roll,'seat':index});
    if(session.game.diceValue!=null && session.game.legalPawnIndices().isEmpty) {
      apply(PassTurnCommand(matchId:id,actorId:actor,expectedStateVersion:session.game.stateVersion,commandId:'$cmd:pass'));
      events.add({'type':'pass'});
    }
  }
  if(action=='execute_move' || (timeout && session.game.diceValue!=null)) {
    final pawn = timeout ? const SeededLudoAi().choosePawn(session.game,seed:session.game.stateVersion) : input['pawn_index'] as int?;
    if(pawn==null) throw StateError('Pawn required');
    apply(MovePawnCommand(matchId:id,actorId:actor,expectedStateVersion:session.game.stateVersion,commandId:'$cmd:move',pawnIndex:pawn));
  }
  final winner=session.game.winner;
  return await api('rest/v1/rpc/commit_ludo_turn',body:{
    'p_match':id,'p_expected':seq,'p_id':cmd,'p_actor':uid,'p_action':action,
    'p_seat':index,'p_timeout':timeout,'p_next':session.game.toSnapshot(),
    'p_events':events,'p_winner':winner==null ? null : colors.indexOf(winner),
  });
}

Future<void> main() async {
  for(final key in ['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY']) {
    if(Platform.environment[key]?.isNotEmpty!=true) throw StateError('Missing $key');
  }
  runTimeoutWorker();
  final server=await HttpServer.bind(InternetAddress.anyIPv4,int.parse(Platform.environment['PORT']??'8080'));
  server.listen((request) async {
    request.response.headers.contentType=ContentType.json;
    try {
      request.response.write(jsonEncode(await turn(request)));
    } catch (_) {
      request.response.statusCode=409;
      request.response.write('{"error":"Command unavailable; refresh match"}');
    } finally {
      await request.response.close();
    }
  });
}

String commandId() {
  final bytes = List<int>.generate(16, (_) => entropy.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

void runTimeoutWorker() {
  var sweeping = false;
  Timer.periodic(const Duration(seconds: 1), (_) async {
    if (sweeping) return;
    sweeping = true;
    try {
      final rooms = await api('rest/v1/matches', query: {
        'status': 'eq.playing',
        'deadline': 'lte.${DateTime.now().toUtc().toIso8601String()}',
        'select': 'id,sequence_number',
        'order': 'deadline.asc',
        'limit': '32',
      }) as List;
      await Future.wait(rooms.map((room) async {
        try {
          await applyIntent({
            'match_id': room['id'],
            'expected_sequence': room['sequence_number'],
            'command_id': commandId(),
          }, 'handle_turn_timeout', 'timeout-worker', null);
        } on StateError {
          // A concurrent worker or a player may already have committed.
        }
      }));
    } catch (_) {
      stderr.writeln('Online timeout sweep failed');
    } finally {
      sweeping = false;
    }
  });
}
