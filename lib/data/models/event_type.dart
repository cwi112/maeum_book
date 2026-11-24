/// 경조사 종류.
///
/// DB에는 enum의 이름('wedding' 등)이 글자로 저장된다. (Drift의 `textEnum`)
/// - 새 종류는 **맨 뒤가 아니어도 자유롭게 추가**할 수 있다. (순서가 아니라 이름으로 저장하기 때문)
/// - 단, 이미 있는 값의 **이름을 바꾸거나 지우면** 기존 데이터를 읽지 못하니 주의한다.
enum EventType {
  wedding('결혼'),
  funeral('조의'),
  firstBirthday('돌잔치'),
  birthday('생일'),
  housewarming('집들이'),
  opening('개업'),
  other('기타');

  const EventType(this.label);

  /// 화면·엑셀에 보여줄 한글 이름
  final String label;
}
