import 'package:zenrun/core/network/api_helper.dart';

class SliderModel {
  int? id;
  String? imageEn;
  String? linkEn;
  int? tartib;
  dynamic imageCh;
  dynamic linkCh;
  dynamic imageIn;
  dynamic linkIn;
  dynamic imageEs;
  dynamic linkEs;
  dynamic imageAr;
  dynamic linkAr;
  dynamic imageFr;
  dynamic linkFr;
  dynamic imageRu;
  dynamic linkRu;
  dynamic imagePo;
  dynamic linkPo;
  dynamic imageBg;
  dynamic linkBg;
  dynamic imageJp;
  dynamic linkJp;
  dynamic imageOd;
  dynamic linkOd;
  dynamic imageAn;
  dynamic linkAn;
  dynamic imageTr;
  dynamic linkTr;
  dynamic imageKo;
  dynamic linkKo;
  dynamic imageFa;
  dynamic linkFa;

  SliderModel({
    this.id,
    this.imageEn,
    this.linkEn,
    this.tartib,
    this.imageCh,
    this.linkCh,
    this.imageIn,
    this.linkIn,
    this.imageEs,
    this.linkEs,
    this.imageAr,
    this.linkAr,
    this.imageFr,
    this.linkFr,
    this.imageRu,
    this.linkRu,
    this.imagePo,
    this.linkPo,
    this.imageBg,
    this.linkBg,
    this.imageJp,
    this.linkJp,
    this.imageOd,
    this.linkOd,
    this.imageAn,
    this.linkAn,
    this.imageTr,
    this.linkTr,
    this.imageKo,
    this.linkKo,
    this.imageFa,
    this.linkFa,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) => SliderModel(
    id: json["id"],
    imageEn: json["image_EN"],
    linkEn: json["link_EN"],
    tartib: json["tartib"],
    imageCh: json["image_CH"],
    linkCh: json["link_CH"],
    imageIn: json["image_IN"],
    linkIn: json["link_IN"],
    imageEs: json["image_ES"],
    linkEs: json["link_ES"],
    imageAr: json["image_AR"],
    linkAr: json["link_AR"],
    imageFr: json["image_FR"],
    linkFr: json["link_FR"],
    imageRu: json["image_RU"],
    linkRu: json["link_RU"],
    imagePo: json["image_PO"],
    linkPo: json["link_PO"],
    imageBg: json["image_BG"],
    linkBg: json["link_BG"],
    imageJp: json["image_JP"],
    linkJp: json["link_JP"],
    imageOd: json["image_OD"],
    linkOd: json["link_OD"],
    imageAn: json["image_AN"],
    linkAn: json["link_AN"],
    imageTr: json["image_TR"],
    linkTr: json["link_TR"],
    imageKo: json["image_KO"],
    linkKo: json["link_KO"],
    imageFa: json["image_FA"],
    linkFa: json["link_FA"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "image_EN": imageEn,
    "link_EN": linkEn,
    "tartib": tartib,
    "image_CH": imageCh,
    "link_CH": linkCh,
    "image_IN": imageIn,
    "link_IN": linkIn,
    "image_ES": imageEs,
    "link_ES": linkEs,
    "image_AR": imageAr,
    "link_AR": linkAr,
    "image_FR": imageFr,
    "link_FR": linkFr,
    "image_RU": imageRu,
    "link_RU": linkRu,
    "image_PO": imagePo,
    "link_PO": linkPo,
    "image_BG": imageBg,
    "link_BG": linkBg,
    "image_JP": imageJp,
    "link_JP": linkJp,
    "image_OD": imageOd,
    "link_OD": linkOd,
    "image_AN": imageAn,
    "link_AN": linkAn,
    "image_TR": imageTr,
    "link_TR": linkTr,
    "image_KO": imageKo,
    "link_KO": linkKo,
    "image_FA": imageFa,
    "link_FA": linkFa,
  };
}