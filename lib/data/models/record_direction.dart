/// 마음(돈)의 방향: 내가 보냈는지, 받았는지.
///
/// DB에는 enum의 이름('sent' / 'received')이 글자로 저장된다. (Drift의 `textEnum`)
/// 그래서 **값의 이름을 바꾸면 기존 데이터를 읽지 못하니** 이름은 바꾸지 말고, 화면 표시는 [label]로 한다.
enum RecordDirection {
  /// 내가 보낸 마음
  sent('보냄', '보냈어요'),

  /// 내가 받은 마음
  received('받음', '받았어요');

  const RecordDirection(this.label, this.actionLabel);

  /// 화면·엑셀에 보여줄 한글 이름
  final String label;

  /// 입력 화면 선택 버튼에 쓰는 문장형 이름 ('보냈어요' / '받았어요')
  final String actionLabel;
}
