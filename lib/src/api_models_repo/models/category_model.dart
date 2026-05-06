class CategoryModel {
  final int? id;
  final String? title;
  final String? image;
  List<SubCategoryModel> subList = [];

  CategoryModel({
    this.id,
    this.title,
    this.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json["id"],
    title: json["title"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
  };
}


class SubCategoryModel {
  final int? id;
  final int? categoryId;
  final String? categoryTitle;
  final String? title;
  final String? image;
  final bool? isAmoozesh;

  SubCategoryModel({
    this.id,
    this.categoryId,
    this.categoryTitle,
    this.title,
    this.image,
    this.isAmoozesh,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) => SubCategoryModel(
    id: json["id"],
    categoryId: json["categoryId"],
    categoryTitle: json["categoryTitle"],
    title: json["title"],
    image: json["image"],
    isAmoozesh: json["isAmoozesh"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "categoryId": categoryId,
    "categoryTitle": categoryTitle,
    "title": title,
    "image": image,
    "isAmoozesh": isAmoozesh,
  };
}