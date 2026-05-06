class ProfileParam {
  String cityId;
  String family;
  String image;
  String isActive;
  String isExpert;
  String name;
  String phone;
  String wallet;

  ProfileParam({
    required this.cityId,
    required this.family,
    required this.image,
    required this.isActive,
    required this.isExpert,
    required this.name,
    required this.phone,
    required this.wallet,
  });

}


class AddressParam {
  String address;
  String codePosti;
  String mapLat;
  String mapLong;
  String phone;
  String title;

  AddressParam({
    required this.address,
    required this.codePosti,
    required this.mapLat,
    required this.mapLong,
    required this.phone,
    required this.title,
  });

}


class OrderParam {
  String addressId;
  String categoryId;
  String cityId;
  String date;
  String description;
  String expertLanguage;
  String expertPhone;
  String id;
  String image1;
  String image2;
  String image3;
  String isFinish;
  String isHurry;
  String isPriceFix;
  String isStart;
  String isUserAcceptPrice;
  String paymentFile;
  String paymentMethod;
  String phone;
  String price;
  String serviceId;
  String state;
  String subCategoryId;
  String titleEn;
  String titleTr;
  String video;
  String categoryTitleEn;
  String categoryTitleTr;
  String subCategoryTitleEn;
  String subCategoryTitleTr;
  String isCanceled;
  String serviceTitleEN;
  String serviceTitleTR;
  String cityTitleEN;
  String cityTitleTR;
  String isPaid;

  OrderParam({
    required this.addressId,
    required this.categoryId,
    required this.cityId,
    required this.date,
    required this.description,
    required this.expertLanguage,
    required this.expertPhone,
    required this.id,
    required this.image1,
    required this.image2,
    required this.image3,
    required this.isFinish,
    required this.isHurry,
    required this.isPriceFix,
    required this.isStart,
    required this.isUserAcceptPrice,
    required this.paymentFile,
    required this.paymentMethod,
    required this.phone,
    required this.price,
    required this.serviceId,
    required this.state,
    required this.subCategoryId,
    required this.titleEn,
    required this.titleTr,
    required this.video,
    required this.categoryTitleEn,
    required this.categoryTitleTr,
    required this.subCategoryTitleEn,
    required this.subCategoryTitleTr,
    required this.isCanceled,
    required this.serviceTitleEN,
    required this.serviceTitleTR,
    required this.cityTitleEN,
    required this.cityTitleTR,
    required this.isPaid,
  });

}
