# 🧰 abapPackage

![ABAP](https://img.shields.io/badge/language-ABAP-blue.svg)
![abapGit](https://img.shields.io/badge/abapGit-compatible-orange)

> A reusable ABAP development package ready for transport via abapGit.

---

## 📌 Overview

**`abapPackage`** is a modular ABAP development package designed for use in SAP NetWeaver systems. It includes well-structured ABAP objects like classes, reports, and interfaces, making it suitable for reuse across different projects or demonstrations.

<div align="center">
  <img src="https://miro.medium.com/v2/resize:fit:1200/1*dMYu2Z4Sv2mXCiT9iHjX6w.jpeg" alt="ABAP Package Overview" width="600"/>
  <p><i>Fig 1: Overview of ABAP package structure</i></p>
</div>

---

## 🚀 Key Features

- 📦 ABAP Classes, Reports, and Includes in one package
- 🔄 Compatible with [abapGit](https://docs.abapgit.org/)
- 🔐 Custom Z-objects that can be reused in other SAP projects
- ⚙️ Simple to install via SAP GUI or Eclipse ADT
- 🧪 SAP transport-ready format for version control

---

## 🛠️ Installation Guide

### Using abapGit (Eclipse or GUI)

1. Clone the repository using:
    ```
    https://github.com/u-Kiran05/abapPackage.git
    ```
2. Open **abapGit** in Eclipse or SAP GUI (transaction code: `ZABAPGIT` or use ADT plugin).
3. Create a new package (`ZABAP_PACKAGE`) or use an existing one.
4. Pull and activate all the objects.
5. Validate using SE80 or Eclipse to confirm objects are activated.



---

## 🧪 Example Usage

```abap
REPORT zreport_sample.

DATA(lo_demo) = NEW zcl_utility_class( ).
lo_demo->execute( ).
