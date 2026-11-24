/// 상대방과의 관계. (선택 입력)
///
/// 사람별 정리·엑셀에서 "어떤 사이였는지"를 함께 보기 위해 기록한다.
/// DB에는 enum 이름('family' 등)이 글자로 저장되므로, **이미 있는 값의 이름은 바꾸지 않는다.**
enum Relation {
  family('가족'),
  relative('친척'),
  friend('친구'),
  work('직장'),
  acquaintance('지인'),
  other('기타');

  const Relation(this.label);

  /// 화면·엑셀에 보여줄 한글 이름
  final String label;
}
