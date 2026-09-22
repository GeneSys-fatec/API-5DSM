class UserData {
  final int id;
  final String name;
  final String email;
  final String? role;

  const UserData({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: (json['id'] as num).toInt(),
      name: (json['nome'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['papel'] ?? json['role']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (role != null) 'role': role,
      };
}

class RegisterRequest {
  final String nome;
  final String email;
  final String senha;
  final String confirmarSenha;

  const RegisterRequest({
    required this.nome,
    required this.email,
    required this.senha,
    required this.confirmarSenha,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'email': email,
        'senha': senha,
        'confirmarSenha': confirmarSenha,
      };
}


class LoginResult {
  final String token;
  final UserData user;

  const LoginResult({
    required this.token,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
