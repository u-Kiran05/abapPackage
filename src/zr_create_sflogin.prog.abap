*&---------------------------------------------------------------------*
*& Report ZR_CREATE_SFLOGIN
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZR_CREATE_SFLOGIN.


*----------------------------------------------------------
* Type Declarations
*----------------------------------------------------------
TYPES: BEGIN OF ty_user,
         bname TYPE xubname,
       END OF ty_user.

*----------------------------------------------------------
* Data Declarations
*----------------------------------------------------------
DATA: lt_user        TYPE TABLE OF ty_user,
      ls_user        TYPE ty_user,
      ls_login       TYPE zpp_sflogin,
      lv_user        TYPE xubname,
      lv_count       TYPE i VALUE 0,
      lt_zpp_sflogin TYPE TABLE OF zpp_sflogin,
      ls_zpp_sflogin TYPE zpp_sflogin.

CONSTANTS: c_default_pwd TYPE zpp_pass_de VALUE 'demo@123'.

*----------------------------------------------------------
* Display current contents of ZPP_SFLOGIN
*----------------------------------------------------------
WRITE: / 'Current contents of ZPP_SFLOGIN before processing:'.
SELECT * FROM zpp_sflogin INTO TABLE lt_zpp_sflogin.
IF lt_zpp_sflogin IS INITIAL.
  WRITE: / 'No records found in ZPP_SFLOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'USERNAME', 30 'PASSWORD'.
  WRITE: / '-----', 10 '--------', 30 '--------'.
  LOOP AT lt_zpp_sflogin INTO ls_zpp_sflogin.
    WRITE: / ls_zpp_sflogin-mandt,
             10 ls_zpp_sflogin-bname,
             30 ls_zpp_sflogin-pass.
  ENDLOOP.
ENDIF.
WRITE: /.

*----------------------------------------------------------
* Fetch up to 20 users from USR02 (SAP login table)
*----------------------------------------------------------
SELECT bname FROM usr02 INTO TABLE lt_user UP TO 20 ROWS.
IF lt_user IS INITIAL.
  WRITE: / 'No user records found in USR02.'.
  RETURN.
ELSE.
  WRITE: / 'Found', lines( lt_user ), 'users in USR02.'.
ENDIF.

*----------------------------------------------------------
* Process each user
*----------------------------------------------------------
CLEAR lv_count.
LOOP AT lt_user INTO ls_user.
  CLEAR: ls_login, lv_user.

  lv_user = ls_user-bname.

  IF lv_user IS INITIAL.
    WRITE: / 'Warning: Empty User ID (BNAME).'.
    CONTINUE.
  ENDIF.

  WRITE: / 'Processing User ID:', lv_user LEFT-JUSTIFIED NO-ZERO.

  ls_login-bname = lv_user.
  ls_login-pass  = c_default_pwd.

  " Insert or update login record
  TRY.
      MODIFY zpp_sflogin FROM ls_login.
      IF sy-subrc = 0.
        ADD 1 TO lv_count.
        WRITE: '→ Inserted/Updated OK'.
      ELSE.
        WRITE: '→ Modify failed. sy-subrc =', sy-subrc.
      ENDIF.
    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
      WRITE: '→ DB Error:', lx_sql->get_text( ).
  ENDTRY.
ENDLOOP.

IF lv_count > 0.
  COMMIT WORK.
  WRITE: / 'Total Shop Floor user records processed:', lv_count.
ELSE.
  WRITE: / 'No records processed.'.
ENDIF.

*----------------------------------------------------------
* Display updated contents
*----------------------------------------------------------
WRITE: /.
WRITE: / 'Contents of ZPP_SFLOGIN after processing:'.
CLEAR lt_zpp_sflogin.
SELECT * FROM zpp_sflogin INTO TABLE lt_zpp_sflogin.
IF lt_zpp_sflogin IS INITIAL.
  WRITE: / 'No records found.'.
ELSE.
  WRITE: / 'MANDT', 10 'USERNAME', 30 'PASSWORD'.
  WRITE: / '-----', 10 '--------', 30 '--------'.
  LOOP AT lt_zpp_sflogin INTO ls_zpp_sflogin.
    WRITE: / ls_zpp_sflogin-mandt,
             10 ls_zpp_sflogin-bname,
             30 ls_zpp_sflogin-pass.
  ENDLOOP.
ENDIF.
