# Zed Git Layout

개인용으로 수정한 Windows Zed와 재설치·공유용 패키지를 관리하는 비공개 저장소입니다. Zed Industries의 공식 배포판은 아닙니다.

**[최신 개인 배포본 다운로드](https://github.com/wow2658/zed-git-layout/releases/latest)** · [전체 배포 이력](https://github.com/wow2658/zed-git-layout/releases) · [업데이트·빌드 방법](../docs/private-build.md)

현재 배포 버전은 **1.28.1-custom.3**, 기반 공식 버전은 **Zed 1.28.1**입니다.

`custom.3`는 개발자 PC의 사용자명과 로컬 빌드 경로를 치환해 다시 빌드한 패키지입니다. GUI와 CLI를 함께 빌드하며, ZIP 생성 시 경로 검사에 통과해야 합니다.

## 설치와 재설치

1. Releases에서 `Zed-Git-Layout-…-win-x64.zip`을 받습니다.
2. ZIP 전체를 압축 해제하고 `Install.cmd`를 실행합니다.
3. 기존 Zed 창을 닫고 **Zed Git Layout** 바로가기로 실행합니다.

새 개인 배포본도 같은 순서로 설치합니다. 이 배포본의 사용자 설정과 확장 데이터는 유지합니다. 소스와 라이선스도 ZIP에 들어 있으므로 다른 사람에게 전달할 때는 ZIP 전체를 전달합니다. 이 저장소와 Release에 접근하려면 저장소 권한이 필요합니다.

## 개인 수정사항

- Changes / History 상하 배치, 경계 드래그와 더블클릭 초기화
- 각 섹션 접기·펼치기 및 작업공간별 상태 저장
- 위쪽 저장소 선택기, 면이 강조된 좌우 패널 배치 아이콘
- History 목록의 커밋 그래프와 왼쪽 헤더의 표시 전환 버튼
- 각 커밋 시점의 PC 시간대 기준 `YYYY-MM-DD HH:mm` 표시

## 관리 방식

| 위치 | 내용 |
| --- | --- |
| `main` | 현재 개인 수정 소스와 배포 도구 |
| `v1.28.1-custom.3` 같은 태그 | 배포 ZIP의 소스 체크포인트 |
| Releases | 설치 ZIP, SHA-256, 검증 결과 |
| 로컬 `origin` | 이 비공개 저장소 |
| 로컬 `upstream` | 공식 [zed-industries/zed](https://github.com/zed-industries/zed) |

GitHub의 공개 fork와 별개의 저장소로 관리합니다. 공식 소스와의 Git 이력은 유지합니다. 큰 실행 파일·ZIP과 개인 로그인/설정 데이터는 소스 커밋에 넣지 않습니다.

## 공식 Zed 업데이트

필요할 때 공식 릴리스 태그를 가져와 별도 브랜치에서 병합하고, 개인 기능과 충돌을 해결한 뒤 다시 빌드해 새 Release를 만듭니다. 공식 업데이트가 우리 ZIP에 자동으로 반영되지는 않습니다.

지금 잘 쓰는 버전은 그대로 유지해도 됩니다. 필요한 기능이나 호환성 수정이 생겼을 때 반영하고, 보안 관련 수정은 별도로 확인합니다. 이전 ZIP과 태그는 복구용으로 보관합니다.

복사된 공식 운영용 workflow가 실행되지 않도록 이 저장소의 GitHub Actions는 꺼두었습니다. 자동 업데이트·자동 배포는 설정하지 않았습니다.

이 배포본은 미서명 개인 빌드입니다. 설치·재설치·제거는 Windows 11 x64의 임시 경로에서 검사했으며, 새 PC와 다른 GPU에서의 GUI 실행은 별도 확인이 필요합니다. 세부 검증 범위는 각 Release의 검증 JSON을 확인하세요.

원본 소프트웨어의 라이선스와 제3자 고지는 유지합니다. 원래 Zed의 소개는 [기존 README](../README.md)에 있습니다.
