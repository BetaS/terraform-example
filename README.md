# Terraform Example

이 저장소는 동일한 3-tier 예제를 세 가지 형태로 정리한 학습용 저장소입니다.

- `problem`: 학생 실습용 템플릿
- `solution-001-3tier`: 평면 파일 구조 정답
- `solution-002-modules`: 모듈화 정답

루트 디렉터리에서는 Terraform 명령을 실행하지 않고, 반드시 각 하위 폴더로 이동해서 작업합니다.

## 디렉터리 설명

### `problem`

`main.tf`만 활성화되어 있고, 나머지 Terraform 파일은 모두 `*.tf_`로 비활성화되어 있습니다.

의도는 다음과 같습니다.

1. 먼저 `problem`에서 `terraform init`을 수행합니다.
2. 풀이할 파일을 `*.tf_`에서 `*.tf`로 바꿉니다.
3. 파일 안의 TODO를 직접 채우면서 Terraform 문법과 리소스 연결 방식을 익힙니다.

예시:

```bash
cd problem
terraform init
mv 00_vpc.tf_ 00_vpc.tf
```

`problem`은 완성본이 아니므로 처음부터 `terraform plan`이 성공하는 것이 목표가 아닙니다.

### `solution-001-3tier`

리소스를 루트의 여러 `.tf` 파일로 나눠둔 정답 버전입니다.

```bash
cd solution-001-3tier
terraform init
```

### `solution-002-modules`

`modules/` 디렉터리를 사용하는 모듈화 정답 버전입니다.

```bash
cd solution-002-modules
terraform init
```

## 학습 권장 순서

1. `problem`에서 네트워크 리소스부터 하나씩 활성화
2. `solution-001-3tier`와 비교하며 구조 확인
3. 마지막으로 `solution-002-modules`에서 모듈화 방식 확인

## 주의사항

- 세 디렉터리는 각각 독립적인 Terraform 작업 디렉터리입니다.
- 같은 AWS 계정에 같은 이름으로 동시에 apply하면 리소스가 충돌할 수 있습니다.
- 기본 provider 설정에는 `sandbox` profile이 들어 있으므로, 필요하면 자신의 AWS CLI 환경에 맞게 수정해야 합니다.
- `.terraform/`, `*.tfstate`, `crash.log` 같은 로컬 산출물은 커밋하지 않습니다.
