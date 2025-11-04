# 리눅스 한영변환기
"dkssudgktpdy" -> "안녕하세요", "되ㅣㅐ" -> "hello"

한/영 키를 잘못 누르고 입력한 텍스트를 단축키로 변환합니다.

[Screencast_20251104_180821.webm](https://github.com/user-attachments/assets/3851112a-8858-4cf4-9eff-edd8fcbe6cf3)


## 지원 환경
KDE + Wayland 지원

## 설치 방법
1. Python 3 설치(3.13만 테스트됨)
2. [eng-kor-toggle.sh](eng-kor-toggle.sh) 저장
3. KDE 설정 -> Shortcuts -> Add New -> Command or Script
4. 저장한 파일 선택
5. 단축키 할당

## 사용 방법
1. 텍스트 선택(예: `gksrmf`)
2. 지정한 단축키 입력
3. 클립보드에 변환된 텍스트가 저장됨(예: `한글`)
4. 붙여넣기

### WIP: 클립보드 자동 붙여넣기
[dotool](https://git.sr.ht/~geb/dotool) 설치 후 프로그램 사용. 현재는 `Ctrl+V`를 dotool을 통해 입력하는 방식으로 구현되었습니다.
