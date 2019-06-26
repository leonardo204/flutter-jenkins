class SysInfo {
  final String id;
  final String password;
  final String server_address;

  SysInfo(this.id, this.password, this.server_address);

  SysInfo.fromJson(Map<String, dynamic> json)
  :id = json['id'],
  password = json['password'],
  server_address = json['server_address'];

  Map<String, dynamic> toJson() =>
  {
    'id' : id,
    'password' : password,
    'server_address' : server_address
  };
}