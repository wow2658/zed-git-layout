# 개인 Zed 소스와 배포본 관리

## 현재 배포 기준

- 공식 기반: `v1.28.1`, `e8bc16acee5ae1937600d571d441c4b5d7b0d288`
- 개인 패키지: `1.28.1-custom.1`
- 패키지 소스: `3c13e6fc83b5cf04df323fd1794034ecbb039f25`
- 실행 파일 SHA-256: `DEC3EF302CCB700833553D8D1D2D11107B31C5E5CB3577E9DBA85CC40FFC1C8E`
- 타깃: Windows x64, Rust 1.98.1, MSVC

현재 ZIP은 이 소스 체크포인트에 태그 `v1.28.1-custom.1`을 붙여 관리한다. 이후 저장소 안내 문서만 바뀌어도 이 태그와 ZIP은 바꾸지 않는다. 기능이나 패키지를 수정하면 새 버전을 만든다.

## 새 PC에서 소스 받기

저장소에 접근할 수 있는 GitHub 계정으로 로그인한 다음 실행한다.

```powershell
git clone https://github.com/wow2658/zed-git-layout.git
cd zed-git-layout
git remote add upstream https://github.com/zed-industries/zed.git
```

실행만 할 경우에는 소스나 컴파일 도구 대신 Release ZIP을 받으면 된다. 공개 저장소의 fork 버튼이나 Sync fork 기능은 사용하지 않는다.

## 공식 신버전을 반영할 때

먼저 현재 변경과 사용자 데이터를 보존하고, 공식 Release Notes를 확인해 반영할 버전을 고른다. 아래 `vX.Y.Z`는 실제 확인한 릴리스 태그로 바꾼다.

```powershell
git fetch upstream tag vX.Y.Z
git switch --no-track -c update/vX.Y.Z origin/main
git merge --no-ff --no-commit vX.Y.Z
```

충돌이 나면 공식 코드와 개인 기능이 모두 유지되도록 해결한다. 특히 다음 파일을 확인한다.

- `crates/git_ui/src/git_panel.rs`: 상하 배치, 저장 상태, 표시 전환, 정확한 시각
- `crates/git_ui/src/git_graph.rs`: History 그래프와 기존 Git Graph 공용 그리기
- `crates/zed/src/main.rs`: 개인 Windows 개발 빌드의 콘솔/언어 감시 처리
- `script/private-distribution/`: 설치·제거·패키지 생성 도구

공식 버전이 같은 기능을 제공하게 되면 개인 구현을 유지할지, 공식 구현으로 대체할지 검토한다. 기존 설정/작업공간 데이터와 그래프 표시 상태도 확인한다. `.rules`의 검토 안내를 에이전트가 임의로 제거하지 않는다.

새 버전의 Rust/MSVC/SDK 요구사항과 `Cargo.lock`을 따르고, 필요한 범위의 검사와 수동 동작 확인을 마친 뒤 병합을 확정한다. 자동으로 현재 설치 파일을 교체하지 않는다. 확인한 업데이트만 `main`에 반영하고 새 개인 버전으로 배포한다.

## Windows 빌드

처음에는 [공식 Windows 빌드 안내](development/windows.md)의 C++ 빌드 도구, Windows SDK, Rust, CMake 등 요구사항을 준비한다.

현재 기반 버전에서는 다음 스크립트로 embedded assets를 포함해 GUI와 CLI를 빌드할 수 있다.

```powershell
powershell -ExecutionPolicy Bypass -File script/private-distribution/Build.ps1 -SourceDirectory .
```

개발 빌드의 이미지·폰트 등이 소스 폴더 없이도 동작하도록 `util/debug-embed`를 사용한다. 표준 Visual Studio SDK 환경을 사용하기 어려운 기존 빌드 PC에서는 기존 SDK 환경 준비 스크립트를 먼저 적용해야 한다. 빌드 산출물을 혼동하지 않도록 공식 기반 버전과 실행 파일 해시를 기록한다.

## 다음 개인 패키지 만들기

1. 기능을 확인하고 소스와 패키지 스크립트를 커밋한다.
2. 기반 버전이 바뀌면 패키지 생성기의 upstream SHA, 버전 정보, CLI·ConPTY·AMD runtime 정보와 라이선스 출처도 함께 갱신한다. GUI와 CLI/runtime은 같은 기반 릴리스에 맞춘다.
3. `cargo-about`으로 Windows 빌드 의존성의 라이선스 고지를 생성한다. 현재 사용 도구 버전은 `0.8.2`다.
4. `Build-Package.ps1`에 새 개인 버전, 실행 파일, runtime 위치, 실행 파일 SHA-256, 생성한 고지를 전달한다.
5. 설치·재설치·제거, 사용자 설정 유지, ZIP/소스/체크섬, 실제 GUI 기능을 확인한다.

예를 들어 같은 공식 기반에서 두 번째 개인 패키지는 `1.28.1-custom.2`, 다른 공식 기반으로 옮기면 `X.Y.Z-custom.1`처럼 구분한다.

```powershell
$guiHash = (Get-FileHash target/debug/zed.exe -Algorithm SHA256).Hash
& script/private-distribution/Build-Package.ps1 `
    -Version '1.28.1-custom.2' `
    -OutputDirectory 'C:\dev\zed-private-releases' `
    -ExecutablePath "$PWD\target\debug\zed.exe" `
    -ExpectedExecutableSha256 $guiHash `
    -RuntimeDirectory 'C:\path\to\matching\zed-runtime' `
    -DependencyLicenses 'C:\path\to\generated-licenses.md'
```

## GitHub에 새 Release 올리기

코드만 Git에 push하고 ZIP은 Release asset으로 올린다. 아래 버전과 파일 경로는 실제 검증한 것으로 바꾼다. 같은 버전의 ZIP을 몰래 바꾸거나 기존 태그를 강제로 이동하지 않는다.

```powershell
git tag -a v1.28.1-custom.2 <검증한-소스-커밋> -m 'Zed Git Layout 1.28.1-custom.2'
git push origin HEAD:main
git push origin v1.28.1-custom.2
gh release create v1.28.1-custom.2 <ZIP> <ZIP.sha256> <검증JSON> `
    --repo wow2658/zed-git-layout --verify-tag `
    --title 'Zed Git Layout 1.28.1-custom.2' --notes-file <릴리스설명파일>
```

Release의 소스 커밋, 패키지 manifest, 소스 ZIP, 실행 파일 해시가 일치하는지 확인한다. 다른 사람과 공유할 때는 비공개 저장소 접근 권한을 부여하거나 소스와 라이선스를 포함한 배포 ZIP 전체를 전달한다.

## 운영 원칙

지금 잘 작동하면 매번 최신판을 따라갈 필요는 없다. 필요한 기능·호환성 변경이 생겼을 때 업데이트하고, 보안 관련 수정은 따로 판단한다. 공식 자동 업데이트는 개인 수정을 덮어쓸 수 있으므로 개인 빌드에서는 꺼둔다.

업데이트 확인 알림, 자동 병합, 자동 빌드/배포는 아직 구성하지 않았다. 원하면 별도 작업으로 범위를 정해 추가한다. 기존 upstream workflow는 보존하지만 이 비공개 저장소의 Actions 자체를 비활성화해 두었다.
