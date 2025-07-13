class ZCL_ZSEGW_EMPBI_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_EMPBI_DPC
  create public .

public section.
protected section.

  methods ZKPIDETAILSSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_EMPBI_DPC_EXT IMPLEMENTATION.


METHOD zkpidetailsset_get_entityset.

  DATA: lt_entityset TYPE STANDARD TABLE OF zhcm_ekpis_s,
        ls_entity    TYPE zhcm_ekpis_s,
        lv_pernr     TYPE pernr_d,
        lv_doj       TYPE begda,
        lv_today     TYPE sy-datum,
        lv_days      TYPE i.

CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING
    input  = lv_pernr
  IMPORTING
    output = lv_pernr.


  " Read EMP_ID from filters
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    IF ls_filter-property = 'EmpId'.
      lv_pernr = ls_filter-select_options[ 1 ]-low.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF lv_pernr IS INITIAL.
    RETURN.
  ENDIF.

  ls_entity-emp_id = lv_pernr.

  " 1. Annual Working Hours from PA0007
  SELECT SINGLE jrstd
    INTO @ls_entity-aworkinghrs
    FROM pa0007
    WHERE pernr = @lv_pernr.

  " 2. Annual Salary from PA0008
  SELECT SINGLE ansal
    INTO @ls_entity-asalary
    FROM pa0008
    WHERE pernr = @lv_pernr.

  " 3. Total Leave Days from PA2001 (KALTG)
  SELECT SINGLE kaltg
    INTO @ls_entity-leaves
    FROM pa2001
    WHERE pernr = @lv_pernr.

  " 4. Compute Tenure Years from PA0000 (Joining Date)
  SELECT SINGLE begda
    INTO @lv_doj
    FROM pa0000
    WHERE pernr = @lv_pernr
      AND stat2 = '3'. " Active

  IF sy-subrc = 0.
    lv_today = sy-datum.
    lv_days = lv_today - lv_doj.
    ls_entity-tenure_years = lv_days / 365.
  ENDIF.

  APPEND ls_entity TO et_entityset.

ENDMETHOD.
ENDCLASS.
