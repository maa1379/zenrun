class ContactUsModel {
  int? id;
  String? description;
  String? site;
  String? instagram;
  String? youtube;
  String? telegram;
  String? whatsapp;
  String? address;
  String? telephone;
  String? fax;

  ContactUsModel({
    this.id,
    this.description,
    this.site,
    this.instagram,
    this.youtube,
    this.telegram,
    this.whatsapp,
    this.address,
    this.telephone,
    this.fax,
  });

  factory ContactUsModel.fromJson(Map<String, dynamic> json) => ContactUsModel(
    id: json["id"],
    description: json["description"],
    site: json["site"],
    instagram: json["instagram"],
    youtube: json["youtube"],
    telegram: json["telegram"],
    whatsapp: json["whatsapp"],
    address: json["address"],
    telephone: json["telephone"],
    fax: json["fax"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "description": description,
    "site": site,
    "instagram": instagram,
    "youtube": youtube,
    "telegram": telegram,
    "whatsapp": whatsapp,
    "address": address,
    "telephone": telephone,
    "fax": fax,
  };
}
