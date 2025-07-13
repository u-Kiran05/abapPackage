REPORT zr_assign_workorder.

PARAMETERS: p_aufnr TYPE aufnr     OBLIGATORY,
            p_empid TYPE pernr_d   OBLIGATORY.

DATA: wa_assign TYPE zmain_woassign,
      lv_aufnr  TYPE aufnr.

START-OF-SELECTION.

* Check if Work Order exists
  SELECT SINGLE aufnr INTO @lv_aufnr
    FROM aufk
    WHERE aufnr = @p_aufnr.

  IF sy-subrc <> 0.
    MESSAGE 'Work Order does not exist in AUFK.' TYPE 'E'.
  ENDIF.

* Check if already assigned
  SELECT SINGLE * INTO @wa_assign
    FROM zmain_woassign
    WHERE aufnr = @p_aufnr
      AND emp_id = @p_empid.

  IF sy-subrc = 0.
    " Already exists: Update assignment
    UPDATE zmain_woassign
      SET assigned_on = @sy-datum,
          status      = 'UPDATED'
      WHERE aufnr = @p_aufnr
        AND emp_id = @p_empid.

    IF sy-subrc = 0.
      MESSAGE 'Work Order reassigned successfully.' TYPE 'S'.
    ELSE.
      MESSAGE 'Update failed.' TYPE 'E'.
    ENDIF.

  ELSE.
    " New assignment
    wa_assign-aufnr       = p_aufnr.
    wa_assign-emp_id      = p_empid.
    wa_assign-assigned_on = sy-datum.
    wa_assign-status      = 'ASSIGNED'.

    INSERT zmain_woassign FROM wa_assign.

    IF sy-subrc = 0.
      MESSAGE 'Work Order assigned successfully.' TYPE 'S'.
    ELSE.
      MESSAGE 'Insert failed. Please check your data.' TYPE 'E'.
    ENDIF.
  ENDIF.
