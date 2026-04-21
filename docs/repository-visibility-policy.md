# Repository Visibility Policy

Updated: 2026-04-22

## 원칙

1. `zuzunza-com/zuzunza` 는 Zuzunza 플랫폼의 **최상위 메타 레포** 이며,
   실제 코드는 모두 서브모듈로 분리한다.
2. 메타 레포에는 **공개되어도 무방한 정보만** 들어간다.
   - 서브모듈 토폴로지, README, 라이선스, 본 정책 문서.
   - 시크릿 / 내부 도메인 / 운영 IP / 내부 런북은 **금지**.
3. 서브모듈의 가시성(공개/비공개)은 각 서브모듈 레포의 설정을 단일 소스로 따른다.
   메타 레포는 서브모듈의 가시성을 강제로 변경하지 않는다.

## 현행 분류 (2026-04-22 기준)

| 레포 | 가시성 | 비고 |
|---|---|---|
| `zuzunza-com/zuzunza`            | 운영자 결정 | 메타 레포. PUBLIC 가능. |
| `zuzunza-com/zuzunza-waterscape` | PRIVATE | 워터스케이프 본체. 운영 코드. |
| `zuzunza-com/zuzunza-ruffle`     | PUBLIC  | Zuzunza Ruffle 포크. |
| `zuzunza-com/zuzunza-cypaper`    | PRIVATE | Cypaper 엣지/DB/infra. |

> 본 분류 외의 레거시 서브 레포(`wscp-*` 계열 8종)는 운영 단일화에 따라
> 메타 레포의 서브모듈 등록에서는 제외된다. 원격 레포 자체는 보존한다.

## 메타 레포 스테이징 규칙

- 본 레포의 `main` 브랜치에 들어갈 수 있는 것:
  - `README.md`, `LICENSE`, `docs/**`, `.gitmodules`, `.gitignore`, `.gitattributes`
  - 서브모듈 포인터(`platform/<name>` 의 gitlink)
- 본 레포의 `main` 브랜치에 들어가서는 안 되는 것:
  - 어떤 형태의 `.env`, 토큰, 키, 인증서
  - 내부 도메인, 내부 IP, 운영 호스트명
  - 내부 런북, 인시던트 메모, 고객 데이터
  - 빌드 산출물(`node_modules`, `dist`, `target`, `bin`, `.next`, `.turbo`)

## 서브모듈 포인터 갱신 절차

```bash
# 특정 서브모듈을 원격 최신 커밋으로
git submodule update --remote platform/<name>

# 변경된 포인터(.git 안 SHA) 를 메타 레포 커밋
git add platform/<name>
git commit -m "chore: bump <name> pointer to <short-sha>"
git push
```

## 시크릿 사고 시

1. 시크릿이 본 레포에 커밋된 즉시 회전(rotate).
2. `git filter-repo` 로 히스토리 정리 후 force-push.
3. 본 정책 문서에 사고 일시와 회전 완료를 기록(요약만).
