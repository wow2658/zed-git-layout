Zed Git Layout — 개인 배포본

설치 / 재설치
1. ZIP 전체를 압축 해제합니다. ZIP 안에서 바로 실행하지 마세요.
2. Install.cmd를 더블클릭합니다. 관리자 권한은 필요 없습니다.
3. 기존 Zed 창을 종료하고 바탕화면 또는 시작 메뉴의 Zed Git Layout을 실행합니다.

이미 설치했다면 같은 순서로 다시 설치합니다. 이 배포본의 설정, 확장과 작업공간 데이터는 유지합니다.
원래 Zed의 설치 경로와 설정은 바꾸지 않습니다. 처음 설치하면 새 설정으로 시작하므로 로그인과 확장 설치는 각자 진행합니다.
Windows의 안정 채널 단일 실행 제한을 공유하므로 공식 Zed와 동시에 실행하지 마세요.

설치 위치: %LOCALAPPDATA%\Programs\ZedGitLayout
설정/확장/작업공간: %LOCALAPPDATA%\ZedGitLayout\UserData
프로그램 제거: Windows 설정 > 앱 > 설치된 앱 > Zed Git Layout (private build)
또는 이 폴더의 Uninstall.cmd를 실행합니다. 제거해도 위 사용자 데이터는 보존합니다.

이 버전의 변경
- Changes와 History 상하 배치, 드래그로 경계 조절, 더블클릭으로 반반 복원
- 섹션별 접기/펼치기와 작업공간별 상태 저장
- 위쪽 저장소 선택기 및 면이 강조된 왼쪽/오른쪽 패널 이동 아이콘
- History 목록 왼쪽의 커밋 그래프 및 왼쪽 헤더의 켜기/끄기 버튼
- 각 커밋 시점의 PC 시간대 기준 YYYY-MM-DD HH:mm 표시

업데이트 / 이전 버전으로 돌아가기
공식 자동 업데이트는 기본 설정에서 꺼두었습니다. 켜면 개인 수정본이 공식 버전으로 바뀔 수 있습니다.
새 개인 배포 ZIP을 받아 Install.cmd를 다시 실행하면 됩니다.
이전 버전 ZIP도 보관해두고 필요할 때 다시 설치하세요. 설치 프로그램은 이전 실행 파일도 versions 폴더에 남깁니다.
사용자 데이터 형식이 달라지는 버전으로 이동할 때는 UserData 폴더를 먼저 백업하세요.

실행 문제
이 패키지는 Windows x64용이며 디지털 서명 없는 개인 빌드입니다.
개발자 PC의 사용자명과 빌드 폴더가 남지 않도록 경로 치환을 적용하고 PRIVACY-CHECK.json으로 검사합니다.
다른 PC의 Smart App Control 등에서 실행이 차단될 수 있습니다. 설치 스크립트는 보안 설정을 변경하지 않습니다.
Git 조작에는 Git for Windows가 필요합니다. Python, Rust, Visual Studio는 실행할 때 필요하지 않습니다.
이 PC에서 확인한 환경은 Windows 11 x64입니다. 새 Windows 설치/다른 GPU에서의 동작까지 검증한 것은 아닙니다.

소스 / 라이선스
Zed Industries의 공식 배포판이 아닌 수정본입니다. 출처와 버전은 BUILD-INFO.txt 및 manifest.json을 보세요.
source 폴더에 수정 소스 전체 ZIP, 변경 패치와 빌드 방법을 함께 넣었습니다.
다른 사람에게 전달할 때도 source와 licenses 폴더를 포함한 ZIP 전체를 전달하세요.
이 소프트웨어의 사용, 수정, 재배포 권리는 동봉한 GPL-3.0-or-later 및 각 구성요소의 라이선스를 따릅니다.
개인 배포 범위로 사용하더라도 받는 사람의 라이선스상 권리를 추가로 제한하지 않습니다.
기존 Zed의 유료 온라인 서비스나 AI 기능 사용 권한을 변경하는 배포본은 아닙니다.

새 배포 만들기
source의 Build.ps1 또는 소스 ZIP 안의 공식 Windows 빌드 문서를 참고하세요.
패키지 생성 스크립트는 소스의 script/private-distribution/Build-Package.ps1입니다.
기능을 고친 뒤에는 버전을 올리고 새 ZIP을 만들어 전달합니다. 별도 GitHub PR이나 공개 업로드는 필요하지 않습니다.
