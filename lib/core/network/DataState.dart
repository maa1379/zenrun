abstract class DataState<T>{
  final T? data;
  final String? error;
  final bool? loading;

  const DataState(this.data, this.error,this.loading);
}

class DataSuccess<T> extends DataState<T>{
  const DataSuccess(T? data) : super(data, null,false);
}

class DataFailed<T> extends DataState<T>{
  const DataFailed(String error) : super(null, error,false);
}

class DataLoading<T> extends DataState<T>{
  const DataLoading(bool loading) : super(null, "",true);
}