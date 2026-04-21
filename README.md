# zuzunza

`zuzunza-com/zuzunza` 는 Zuzunza 플랫폼의 **최상위 메타 레포** 입니다.
실제 코드는 모두 **서브모듈**로 분리되어 있고, 이 레포는 다음만 책임집니다.

1. 어떤 하위 레포가 어떤 커밋으로 묶여 함께 배포되는지 **고정(pinning)**
2. 서브모듈 간 관계 / 배포 토폴로지 **문서화**
3. 공개 가능한 수준의 **개요 / 라이선스 / 가시성 정책** 제공

> 본 레포에는 어떤 시크릿 · 내부 인프라 스크립트 · 내부 도메인 · 운영 IP · 내부 런북도 들어가지 않습니다.
> 그런 자료는 모두 비공개 서브모듈 또는 별도 운영 저장소에서만 관리됩니다.

---

## 토폴로지

```text
zuzunza  (이 레포 / 최상위 메타)
└── platform/
    ├── zuzunza-waterscape   (PRIVATE 서브모듈)
    ├── zuzunza-ruffle       (PUBLIC  서브모듈)
    └── zuzunza-cypaper      (PRIVATE 서브모듈)
```

| 서브모듈 | 가시성 | 역할 (요약) |
|---|---|---|
| `platform/zuzunza-waterscape` | PRIVATE | 워터스케이프 본체 모노레포 (프론트엔드 / Go 서비스군 / 인프라). 비공개 운영 코드. |
| `platform/zuzunza-ruffle`     | PUBLIC  | Zuzunza 가 운영하는 Ruffle(Flash 런타임) 포크. 외부 협업 가능. |
| `platform/zuzunza-cypaper`    | PRIVATE | Cypaper 엣지 / DB / infra 묶음. 비공개. |

비공개 서브모듈은 권한이 없는 사용자에게는 **포인터(SHA)만** 노출되고 내용은 fetch 되지 않습니다.
즉, 이 레포가 PUBLIC 이어도 비공개 코드는 그대로 비공개로 유지됩니다.

---

## 사용

### 단순 열람 (공개 부분만)

```bash
git clone https://github.com/zuzunza-com/zuzunza.git
cd zuzunza
git submodule update --init platform/zuzunza-ruffle
```

### 권한이 있는 개발자 (전체 체크아웃)

```bash
git clone https://github.com/zuzunza-com/zuzunza.git
cd zuzunza
git submodule sync  --recursive
git submodule update --init --recursive
```

비공개 서브모듈에 접근하려면 GitHub 계정에 해당 PRIVATE 레포 권한이 있어야 합니다.

### 특정 서브모듈만 업데이트

```bash
git submodule update --remote platform/zuzunza-waterscape
git add  platform/zuzunza-waterscape
git commit -m "chore: bump waterscape pointer"
```

---

## 가시성 / 보안 정책

- 본 레포(메타): 공개 / 비공개는 운영자가 결정. 어느 쪽이든 들어가는 정보는 **공개 가능 수준**으로 제한.
- 서브모듈: 각 서브모듈 자체의 가시성 설정을 **단일 소스**로 따른다. 메타 레포에서는 가시성 변경을 강제하지 않는다.
- 시크릿: 어떤 형태의 비밀(`.env`, 토큰, 키, 인증서)도 본 레포에 커밋 금지. 서브모듈 측은 각자의 `.gitignore` 와 운영 정책을 따른다.
- 자세한 정책: [`docs/repository-visibility-policy.md`](docs/repository-visibility-policy.md)

---

## 라이선스

각 서브모듈은 각자의 `LICENSE` 를 따릅니다.
본 메타 레포의 README · docs 는 별도 표시가 없는 한 운영자 내부 문서로 취급됩니다.
