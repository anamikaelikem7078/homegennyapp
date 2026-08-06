/// Standard API envelope matching backend response shape.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
  });

  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final ApiMeta? meta;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
      meta: json['meta'] != null
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
        'success': success,
        'message': message,
        if (data != null) 'data': toJsonT(data as T),
        if (errors != null) 'errors': errors,
        if (meta != null) 'meta': meta!.toJson(),
      };
}

class ApiMeta {
  const ApiMeta({
    this.page,
    this.perPage,
    this.total,
    this.totalPages,
    this.hasMore,
  });

  final int? page;
  final int? perPage;
  final int? total;
  final int? totalPages;
  final bool? hasMore;

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
        page: json['page'] as int?,
        perPage: json['per_page'] as int? ?? json['perPage'] as int?,
        total: json['total'] as int?,
        totalPages: json['total_pages'] as int? ?? json['totalPages'] as int?,
        hasMore: json['has_more'] as bool? ?? json['hasMore'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
        if (total != null) 'total': total,
        if (totalPages != null) 'total_pages': totalPages,
        if (hasMore != null) 'has_more': hasMore,
      };
}

/// Paginated list response for cursor/page-based APIs.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    this.hasMore = false,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;

  bool get hasNextPage => hasMore || (page * perPage < total);

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT, {
    String itemsKey = 'items',
  }) {
    final rawItems = json[itemsKey] as List<dynamic>? ?? json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PaginatedResponse(
      items: rawItems.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      page: meta['page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? meta['perPage'] as int? ?? rawItems.length,
      total: meta['total'] as int? ?? rawItems.length,
      hasMore: meta['has_more'] as bool? ?? meta['hasMore'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T item) toJsonT) => {
        'items': items.map((e) => toJsonT(e)).toList(),
        'page': page,
        'per_page': perPage,
        'total': total,
        'has_more': hasMore,
      };
}

class PaginationParams {
  const PaginationParams({this.page = 1, this.perPage = 20, this.query});

  final int page;
  final int perPage;
  final String? query;

  Map<String, dynamic> toQueryParams() => {
        'page': page,
        'per_page': perPage,
        if (query != null && query!.isNotEmpty) 'q': query,
      };
}
