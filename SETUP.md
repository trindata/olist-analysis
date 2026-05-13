# Setup do Projeto

Este projeto foi desenvolvido e testado utilizando **Python 3.12.x** e pressupõe o uso de um **ambiente virtual isolado (.venv)** para garantir reprodutibilidade e evitar conflitos de dependências.

> **Pré-requisito**: este guia assume que você já possui o **pyenv** instalado e configurado em sua máquina. Caso não possua, consulte a seção **EXTRA – Primeiro setup em sua máquina** ao final deste documento.

---

## 1. Inicialização do ambiente virtual

Defina a versão do Python utilizada pelo projeto e crie o ambiente virtual local:

```PowerShell
pyenv local 3.12.6
python -m venv .venv
```

Ative o ambiente virtual:

```PowerShell
.venv\Scripts\Activate.ps1
```

Atualize ferramentas fundamentais do Python:

```PowerShell
python -m pip install --upgrade pip setuptools wheel
```

---

## 2. Instalação das dependências do projeto

Instale as bibliotecas necessárias para execução do projeto:

```PowerShell
pip install -r requirements.txt
```
---

## 3. Validações iniciais do ambiente

Verifique se o Python ativo pertence ao ambiente virtual:

```PowerShell
python -c "import sys; print(sys.executable)"
```

**Resultado esperado:**
```text
...\seu_projeto\.venv\Scripts\python.exe
```

Essa validação garante que o projeto será executado com o interpretador correto.

---

## 4. Premissas técnicas do projeto

- O projeto foi desenvolvido e validado exclusivamente com **Python 3.12.x**
- Recomenda-se fortemente manter a execução sempre dentro do ambiente virtual `.venv`

## Troubleshooting

### Recriação do ambiente virtual

Caso ocorram erros relacionados a dependências, kernel ou versão do Python, recrie o ambiente virtual:

```PowerShell
deactivate
Remove-Item .venv -Recurse -Force
```

Em seguida, repita o processo descrito na **Seção 1**.

---

