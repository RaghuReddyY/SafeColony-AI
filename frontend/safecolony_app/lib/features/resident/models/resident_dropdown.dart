class ResidentDropdown {

  final int id;

  final String name;

  final String flat;

  ResidentDropdown({

    required this.id,

    required this.name,

    required this.flat,
  });

  factory ResidentDropdown.fromJson(
      Map<String, dynamic> json) {

    return ResidentDropdown(

      id: json["id"],

      name: json["name"],

      flat: json["flat"],
    );
  }
}