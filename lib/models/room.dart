import 'player.dart';

class Room {
  final String id;
  final String name;
  final List<Player> players;
  final List<String?> board;
  final String? currentPlayer;
  final bool isPrivate;
  final bool gameOver;
  final String? winner;
  final List<int>? winPattern;

  Room({
    required this.id,
    required this.name,
    required this.players,
    required this.board,
    this.currentPlayer,
    required this.isPrivate,
    this.gameOver = false,
    this.winner,
    this.winPattern,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      board: (json['board'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList() ?? List.filled(9, null),
      currentPlayer: json['currentPlayer'],
      isPrivate: json['isPrivate'] ?? false,
      gameOver: json['gameOver'] ?? false,
      winner: json['winner'],
      winPattern: (json['winPattern'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  Room copyWith({
    String? id,
    String? name,
    List<Player>? players,
    List<String?>? board,
    String? currentPlayer,
    bool? isPrivate,
    bool? gameOver,
    String? winner,
    List<int>? winPattern,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      isPrivate: isPrivate ?? this.isPrivate,
      gameOver: gameOver ?? this.gameOver,
      winner: winner ?? this.winner,
      winPattern: winPattern ?? this.winPattern,
    );
  }
}