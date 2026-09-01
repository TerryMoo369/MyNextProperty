class QueryBuilder {
  final List<String> _filters = [];
  final List<String> _contains = [];
  String? _range;
  String? _dateStart;
  String? _dateEnd;
  String? _sort;
  int? _limit;
  List<String> _include = [];
  List<String> _exclude = [];

  void addFilter(String column, String value, {bool caseSensitive = false}) {
    final prefix = caseSensitive ? 'filter' : 'ifilter';
    _filters.add('$prefix=$value@$column');
  }

  void addContains(String column, String value, {bool caseSensitive = false}) {
    final prefix = caseSensitive ? 'contains' : 'icontains';
    _contains.add('$prefix=$value@$column');
  }

  void setRange(String column, {num? begin, num? end}) {
    final b = begin != null ? begin.toString() : '';
    final e = end != null ? end.toString() : '';
    _range = 'range=$column[$b:$e]';
  }

  void setDateRange(String dateColumn, {String? startDate, String? endDate}) {
    if (startDate != null) _dateStart = 'date_start=$startDate@$dateColumn';
    if (endDate != null) _dateEnd = 'date_end=$endDate@$dateColumn';
  }

  void setSort(List<String> sortColumns) {
    if (sortColumns.isNotEmpty) {
      _sort = 'sort=${sortColumns.join(',')}';
    }
  }

  void setLimit(int limit) {
    _limit = limit;
  }

  void setInclude(List<String> columns) {
    _include = columns;
  }

  void setExclude(List<String> columns) {
    _exclude = columns;
  }

  String build() {
    final List<String> params = [];

    if (_filters.isNotEmpty) params.addAll(_filters);
    if (_contains.isNotEmpty) params.addAll(_contains);
    if (_range != null) params.add(_range!);
    if (_dateStart != null) params.add(_dateStart!);
    if (_dateEnd != null) params.add(_dateEnd!);
    if (_sort != null) params.add(_sort!);
    if (_limit != null) params.add('limit=$_limit');
    if (_include.isNotEmpty) params.add('include=${_include.join(',')}');
    if (_exclude.isNotEmpty) params.add('exclude=${_exclude.join(',')}');

    return params.join('&');
  }
}