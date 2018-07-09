
{*******************************************************}
{                                                       }
{       Borland Delphi Visual Component Library         }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

unit DbConsts;

interface

resourcestring
//5  SInvalidFieldSize = 'Invalid field size';
//5  SInvalidFieldKind = 'Invalid FieldKind';
  SInvalidFieldSize = 'Неверный размер поля';                                //5
  SInvalidFieldKind = 'Неверный тип поля';                                   //5

  SInvalidFieldRegistration = 'Invalid field registration';

//5  SUnknownFieldType = 'Field ''%s'' is of an unknown type';
//5  SFieldNameMissing = 'Field name missing';
//5  SDuplicateFieldName = 'Duplicate field name ''%s''';
//5  SFieldNotFound = 'Field ''%s'' not found';
//5  SFieldAccessError = 'Cannot access field ''%s'' as type %s';
//5  SFieldValueError = 'Invalid value for field ''%s''';
//5  SFieldRangeError = '%g is not a valid value for field ''%s''. The allowed range is %g to %g';
//5  SInvalidIntegerValue = '''%s'' is not a valid integer value for field ''%s''';
//5  SInvalidBoolValue = '''%s'' is not a valid boolean value for field ''%s''';
//5  SInvalidFloatValue = '''%s'' is not a valid floating point value for field ''%s''';
  SUnknownFieldType = 'Тип поля ''%s'' неизвестен';                          //5
  SFieldNameMissing = 'Неверное имя поля';                                   //5
  SDuplicateFieldName = 'Дублирование имени поля ''%s''';                    //5
  SFieldNotFound = 'Поле ''%s'' не найдено';                                 //5
  SFieldAccessError = 'Не могу обратиться к полю ''%s'' как к типу %s';      //5
  SFieldValueError = 'Неверное значение для поля ''%s''';                    //5
  SFieldRangeError = '%g неверное значение для поля ''%s''. Должно быть от %g до %g';//5
  SInvalidIntegerValue = '''%s'' неверное целое значение для поля ''%s''';   //5
  SInvalidBoolValue = '''%s'' неверное логическое значение для поля ''%s'''; //5
  SInvalidFloatValue = '''%s'' неверное числовое значение для поля ''%s''';  //5

  SFieldTypeMismatch = 'Type mismatch for field ''%s'', expecting: %s actual: %s';
  SFieldSizeMismatch = 'Size mismatch for field ''%s'', expecting: %d actual: %d';
  SInvalidVarByteArray = 'Invalid variant type or size for field ''%s''';

//5  SFieldOutOfRange = 'Value of field ''%s'' is out of range';
//5  SBCDOverflow = '(Overflow)';
//5  SFieldRequired = 'Field ''%s'' must have a value';
  SFieldOutOfRange = 'Значение поля ''%s'' выходит за допустимые пределы';   //5
  SBCDOverflow = '(Переполнение)';                                           //5
  SFieldRequired = 'Поле ''%s'' должно иметь значение';                      //5

  SDataSetMissing = 'Field ''%s'' has no dataset';
  SInvalidCalcType = 'Field ''%s'' cannot be a calculated or lookup field';

//5  SFieldReadOnly = 'Field ''%s'' cannot be modified';
  SFieldReadOnly = 'Поле ''%s'' нельзя изменить';                            //5

  SFieldIndexError = 'Field index out of range';
  SNoFieldIndexes = 'No index currently active';
  SNotIndexField = 'Field ''%s'' is not indexed and cannot be modified';
  SIndexFieldMissing = 'Cannot access index field ''%s''';
  SDuplicateIndexName = 'Duplicate index name ''%s''';
  SNoIndexForFields = 'No index for fields ''%s''';
  SIndexNotFound = 'Index ''%s'' not found';
  SDuplicateName = 'Duplicate name ''%s'' in %s';
  SCircularDataLink = 'Circular datalinks are not allowed';
  SLookupInfoError = 'Lookup information for field ''%s'' is incomplete';
  SDataSourceChange = 'DataSource cannot be changed';
  SNoNestedMasterSource = 'Nested datasets cannot have a MasterSource';

//5  SDataSetOpen = 'Cannot perform this operation on an open dataset';
//5  SNotEditing = 'Dataset not in edit or insert mode';
//5  SDataSetClosed = 'Cannot perform this operation on a closed dataset';
//5  SDataSetEmpty = 'Cannot perform this operation on an empty dataset';
//5  SDataSetReadOnly = 'Cannot modify a read-only dataset';
  SDataSetOpen = 'Не могу выполнить эту операцию на открытом наборе данных';    //5
  SNotEditing = 'Набор данных не находится в режиме редактирования или вставки';//5
  SDataSetClosed = 'Не могу выполнить эту операцию на закрытом наборе данных';  //5
  SDataSetEmpty = 'Не могу выполнить эту операцию на пустом наборе данных';     //5
  SDataSetReadOnly = 'Не могу изменить набор данных ''только для чтения''';     //5

  SNestedDataSetClass = 'Nested dataset must inherit from %s';
  SExprTermination = 'Filter expression incorrectly terminated';
  SExprNameError = 'Unterminated field name';
  SExprStringError = 'Unterminated string constant';
  SExprInvalidChar = 'Invalid filter expression character: ''%s''';
  SExprNoLParen = '''('' expected but %s found';
  SExprNoRParen = ''')'' expected but %s found';
  SExprNoRParenOrComma = ''')'' or '','' expected but %s found';
  SExprExpected = 'Expression expected but %s found';
  SExprBadField = 'Field ''%s'' cannot be used in a filter expression';
  SExprBadNullTest = 'NULL only allowed with ''='' and ''<>''';
  SExprRangeError = 'Constant out of range';
  SExprNotBoolean = 'Field ''%s'' is not of type Boolean';
  SExprIncorrect = 'Incorrectly formed filter expression';
  SExprNothing = 'nothing';
  SExprTypeMis = 'Type mismatch in expression';
  SExprBadScope = 'Operation cannot mix aggregate value with record-varying value';
  SExprNoArith = 'Arithmetic in filter expressions not supported';
  SExprNotAgg = 'Expression is not an aggregate expression';
  SExprBadConst = 'Constant is not correct type %s';
  SExprNoAggFilter = 'Aggregate expressions not allowed in filters';
  SExprEmptyInList = 'IN predicate list may not be empty';
  SInvalidKeywordUse = 'Invalid use of keyword';
  STextFalse = 'False';
  STextTrue = 'True';
//5  SParameterNotFound = 'Parameter ''%s'' not found';
  SParameterNotFound = 'Параметр ''%s'' не найден';                          //5

  SInvalidVersion = 'Unable to load bind parameters';
  SParamTooBig = 'Parameter ''%s'', cannot save data larger than %d bytes';
  SBadFieldType = 'Field ''%s'' is of an unsupported type';
  SAggActive = 'Property may not be modified while aggregate is active';
  SProviderSQLNotSupported = 'SQL not supported: %s';
  SProviderExecuteNotSupported = 'Execute not supported: %s';
  SExprNoAggOnCalcs = 'Field ''%s'' is not the correct type of calculated field to be used in an aggregate, use an internalcalc';

//5  SRecordChanged = 'Record changed by another user';
  SRecordChanged = 'Запись изменена другим пользователем';

  { DBCtrls }
  SFirstRecord = 'First record';
  SPriorRecord = 'Prior record';
  SNextRecord = 'Next record';
  SLastRecord = 'Last record';
  SInsertRecord = 'Insert record';
  SDeleteRecord = 'Delete record';
  SEditRecord = 'Edit record';
  SPostEdit = 'Post edit';
  SCancelEdit = 'Cancel edit';
  SRefreshRecord = 'Refresh data';

//5  SDeleteRecordQuestion = 'Delete record?';
//5  SDeleteMultipleRecordsQuestion = 'Delete all selected records?';
//5  SRecordNotFound = 'Record not found';
  SDeleteRecordQuestion = 'Удалить запись?';                                 //5
  SDeleteMultipleRecordsQuestion = 'Удалить все выделенные записи?';         //5
  SRecordNotFound = 'Запись не найдена';                                     //5

  SDataSourceFixed = 'Operation not allowed in a DBCtrlGrid';
  SNotReplicatable = 'Control cannot be used in a DBCtrlGrid';
  SPropDefByLookup = 'Property already defined by lookup field';
  STooManyColumns = 'Grid requested to display more than 256 columns';

  { DBLogDlg }
  SRemoteLogin = 'Remote Login';

  { DBOleEdt }
  SDataBindings = 'Data Bindings...';

implementation

end.
