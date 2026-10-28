import '../models/category_model.dart';

class CategoryUtils {
  CategoryUtils._();

  static bool isClothing(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    return normalized == 'clothing' ||
        normalized == 'clothes' ||
        normalized.contains('clothing');
  }

  static String nameForId(String categoryId, List<CategoryModel> categories) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.categoryName;
      }
    }
    return '';
  }

  static bool isClothingProduct(
    String categoryId,
    List<CategoryModel> categories,
  ) {
    return isClothing(nameForId(categoryId, categories));
  }
}
