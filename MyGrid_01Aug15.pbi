;- MyGrid by said 
;  Update of Aug 2015
;  * reducing mouse flickering
;  * allow to hide Focus-rectangle (via setting Color_FocusBorder to -1)
;  Updated for PB 5.20 - Aug 2013
;  Editable; Can resize/hide/freeze Cols/Rows; Text alignment/wraping; 
;  unlimited number of cols/rows; live scrolling
;  can set at cell level: font/forecolor/backcolor/align/... via styles
;  a style is a set of attributes and can be assigned to one or more cells
;  cell can be : text/checkbox/combo/button (defined in style)
;  * 1 col-header & 1 row header by default (headers are not accessible to end-user)
;  * can define a span (multi-cells), a span is assigned the style of its first cell
;  * Navigation keys (Ctrl+ Home/End/Up/Down) + mouse wheel
;  * When a button is clicked, will trigger: #MyGrid_Event_Click
;     Grid-attributes: #MyGrid_Att_ClickedRow, #MyGrid_Att_ClickedCol can be consulted to see where it took place
;  * When a change occurs in text/checkbox/combo, will trigger: #MyGrid_Event_Change
;     Grid-attributes: #MyGrid_Att_ChangedRow, #MyGrid_Att_ChangedCol can be consulted to see where it took place
;     and MyGrid_LastChangedCellText()  can return previous text and MyGrid_GetText() newly entered text
;  * Editing: 2 modes are available and can bet set at cell level (always via styles)
;    In both modes, Enter abd Dbl-Click will open for editing; ESC will exit without validating new text; Click-away will exit and validate new text
;    1. Append : append (newly typed text is appended to exising) & nav-keys do not exit cell
;    2. Over   : overwrites (newly typed text overwrites exising) & nav-keys exit cell being edited with validation
;
;  * should work on all OS (tested on Windows x86/x64 and MAC OS)
EnableExplicit

;{ data structures and constants

CompilerSelect #PB_Compiler_OS
  CompilerCase #PB_OS_Linux           ; might need be tuned!
    #MyGrid_Text_MarginX       = 4  ; left/right margin in pixel
    #MyGrid_Text_MarginY       = 2  ; left/right margin in pixel
    
    #MyGrid_RowSep_Margin      = 6  ; 
    #MyGrid_ColSep_Margin      = 6  ; mouse-margin in pixel
    
    #MyGrid_Scroll_Width       = 16 ; 
    #MyGrid_Default_ColWidth   = 60 ; 
    #MyGrid_Default_RowHeight  = 20 ; 
    #MyGrid_CheckBox_Width     = 16 ; 
    #MyGrid_CheckBox_Color     = $AACD66    ; square boredr color 
    #MyGrid_Combo_Height       = 80 ; height of listview associated with combo-cells
    
  CompilerCase #PB_OS_MacOS           ; might need be tuned!
    #MyGrid_Text_MarginX       = 4  ; left/right margin in pixel
    #MyGrid_Text_MarginY       = 2  ; left/right margin in pixel
    
    #MyGrid_RowSep_Margin      = 4  ; 
    #MyGrid_ColSep_Margin      = 4  ; mouse-margin in pixel
    
    #MyGrid_Scroll_Width       = 16 ; 
    #MyGrid_Default_ColWidth   = 60 ; 
    #MyGrid_Default_RowHeight  = 24 ; 
    #MyGrid_CheckBox_Width     = 16 ; 
    #MyGrid_CheckBox_Color     = $AACD66    ; square boredr color 
    #MyGrid_Combo_Height       = 80 ; 
    
  CompilerDefault
    #MyGrid_Text_MarginX       = 4 ; left/right margin in pixel
    #MyGrid_Text_MarginY       = 2 ; left/right margin in pixel
    
    #MyGrid_RowSep_Margin      = 6 ; 
    #MyGrid_ColSep_Margin      = 6 ; mouse-margin in pixel
    
    #MyGrid_Scroll_Width       = 16 ; 
    #MyGrid_Default_ColWidth   = 60 ; 
    #MyGrid_Default_RowHeight  = 20 ; 
    #MyGrid_CheckBox_Width     = 16 ; 14,16
    #MyGrid_CheckBox_Color     = $AACD66    ; square boredr color 
    #MyGrid_Combo_Height       = 80 ; 
    
CompilerEndSelect

Enumeration                         ; horizontal alignment
  #MyGrid_Align_Left      = 0     ; text left alignment - default
  #MyGrid_Align_Center            ; text center alignment
  #MyGrid_Align_Right             ; text right alignment
EndEnumeration

Enumeration                         ; cell type
  #MyGrid_CellType_Normal    = 0  ; 
  #MyGrid_CellType_Checkbox       ; 
  #MyGrid_CellType_Button         ; 
  #MyGrid_CellType_Combo          ; 
EndEnumeration
Enumeration                         ; data type
  #MyGrid_DataType_Text      = 0  ; 
  #MyGrid_DataType_Number         ; 
  #MyGrid_DataType_DateTime       ; 
EndEnumeration

#MyGrid_Scroll_Max          = 10000
#MyGrid_Scroll_PageSize     = 20

#MyGrid_RC_Any              = -30       ; special value (<0) -> any row or any col
#MyGrid_RC_Data             = -20       ; special value (<0) -> any row or any col that is not header


; All possible mouse-move actions
Enumeration
  #MyGrid_MouseMove_Nothing = 0       ; just changing the cursor ...
  #MyGrid_MouseMove_Resize            ; resizing col/row
  #MyGrid_MouseMove_Select            ; selecting a block
EndEnumeration
Enumeration
  #MyGrid_Move_Focus  = 0             ; what to move
  #MyGrid_Move_TopRC                  ; 
  #MyGrid_Move_Block                  ; 
EndEnumeration

Enumeration                             ; Color-attributes
  #MyGrid_Color_Line = 0              ; grid-line color
  #MyGrid_Color_Background            ; grey-area color
  #MyGrid_Color_FocusBack             ; while editing text-cells
  #MyGrid_Color_FocusBorder           ; 
  #MyGrid_Color_BlockBack             ; block highlight
EndEnumeration

Enumeration                             ; Editing modes - part of style (can be set at cell level))
  ; in both modes: Dbl-Click and Enter will open editing with append, esc/click away will exit 
  #MyGrid_Edit_Over   = 1             ; 
  #MyGrid_Edit_Append = 0             ; 
EndEnumeration

Enumeration                             ; Row/Col attributes
  #MyGrid_Att_Row = 0                 ; row of current cell
  #MyGrid_Att_Col                     ;
  #MyGrid_Att_RowCount                ; 
  #MyGrid_Att_ColCount                ; 
  #MyGrid_Att_RowHeight               ; 
  #MyGrid_Att_ColWdith                ; 
  #MyGrid_Att_TopRow
  #MyGrid_Att_TopCol
  #MyGrid_Att_FrozenRow
  #MyGrid_Att_FrozenCol
  #MyGrid_Att_Block_Row2    
  #MyGrid_Att_Block_Col2    
  #MyGrid_Att_NonHiddenRow
  #MyGrid_Att_NonHiddenCol
  #MyGrid_Att_ChangedRow              ; Cell where last change has occured via editing
  #MyGrid_Att_ChangedCol              ; 
  #MyGrid_Att_ClickedRow              ; Cell where last click has occured
  #MyGrid_Att_ClickedCol              ; 
  
  #MyGrid_Att_GadgetRowScroll         ; Gadget nbr of Row-Scroll - in case
  #MyGrid_Att_GadgetColScroll         ; Gadget nbr of Col-Scroll
  
EndEnumeration

Enumeration #PB_Event_FirstCustomValue
  ; external events returned to caller application
  #MyGrid_Event_Change            ; fired when cell content has changed from outside / #MyGrid_Att_ChangedRow and #MyGrid_Att_ChangedCol can be used to see what cell has changed
  #MyGrid_Event_Click             ; fired when a button-cell received a full clikc   / #MyGrid_Att_ClickedRow and #MyGrid_Att_ClickedCol can be used to see what cell has been clicked
EndEnumeration

; private constants used to exit editing
Enumeration                             ; 
  #_MyGrid_ExitEdit = 10000            ; 
  #_MyGrid_ExitEdit_Vld                ; 
  #_MyGrid_ExitEdit_Vld_Lt             ; exit editing + validation + move left
  #_MyGrid_ExitEdit_Vld_Rt             ; exit editing + validation + move right
  #_MyGrid_ExitEdit_Vld_Up             ; exit editing + validation + move up
  #_MyGrid_ExitEdit_Vld_Dn             ; exit editing + validation + move down
  #_MyGrid_ExitEdit_Vld_PUp            ; exit editing + validation + move up
  #_MyGrid_ExitEdit_Vld_PDn            ; exit editing + validation + move down
  #_MyGrid_ExitEdit_Out                ; 
EndEnumeration


Structure _MyGrid_AreaCol_Type      ; Areas are dynamic depends on width of shown-columns/and height of shown-rows
  X.i                             ; Area of the canvas gadget that can receive events
  Width.i                         ; actual drawn width
  Col.i                           ; related col >= 0
EndStructure

Structure _MyGrid_AreaRow_Type      ; Areas are dynamic depends on width of shown-columns/and height of shown-rows
  Y.i                             ; Area of the canvas gadget that can receive events
  Height.i                        ; actual drawn height
  Row.i                           ; related row >= 0
EndStructure

Structure _MyGrid_Rectangle_Type
  X.i                             ; 
  Y.i                             ; 
  W.i                             ; 
  H.i                             ; 
EndStructure

Structure _MyGrid_CellStyle_Type
  Aling.i
  BackColor.i
  ForeColor.i
  Font.i
  CellType.i
  DataType.i                      ; Text/Number/DateTime
  Editable.i
  EditMode.i
  Gradient.i                      ; 0/1
  List Item.s()                   ; when celltype is a combo, this is the seq of items to display
EndStructure

Structure _MyGrid_MultiCell_Type    ; multi-cells or merged cells (cell span rows/cols)
  R1.i
  C1.i
  R2.i
  C2.i
EndStructure

Structure _MyGrid_Type
  Window.i                        ; window number containing the grid (active)
  
  Gadget.i                        ; associated canvas gagdet number
  GadgetX.i
  GadgetY.i
  GadgetW.i                       ; gadget width
  GadgetH.i                       ; gadget height
  
  WrapText.i
  
  ; sub-gadgets created while creating the Grid
  ColScroll.i                     ; gadget-nbr of attached hor sroll bar
  StateFactorCol.f                ; CurTop = Facor * State
  ColScrollMin.i                  ; Min-State for scrollbar ColScroll
  ColScrollMax.i                  ; Max-State for scrollbar ColScroll
  
  RowScroll.i                     ; gadget-nbr of attached ver sroll bar
  StateFactorRow.f                ; CurTop = Facor * State
  RowScrollMin.i                  ; Min-State for scrollbar RowScroll
  RowScrollMax.i                  ; Max-State for scrollbar RowScroll
  
  TxtEdit.i
  CmbEdit.i
  CmbEditCurStyle.i
  
  AttachedPopupMenu.i
  
  ; data in memory
  Rows.i
  Array RowHeight.i(0)            ; dimensioned by Rows
  
  Cols.i
  Array ColWidth.i(0)             ; dimensioned by Cols
  Array ColID.s(0)                ; dimensioned by Cols
  Map   DicColID.i()              ; map of Unique ID to identify a Column, Cols can be accessed by index or by ID
  
  LastIndex.i                      ; ArraySzie(gData()) = (Rows+1)*(Cols+1)-1
  Array gData.s(0)                 ; grid data - One big array: row after row for data only (no header)
  
  ; current cell
  Row.i                           ; (Row, Col) of Current Cell
  Col.i
  
  TopRow.i                        ; (Row, Col) of Cell shown in Area(1,1)
  TopCol.i
  FrstTopRow.i
  LastTopRow.i
  FrstTopCol.i
  LastTopCol.i
  
  FrstVisRow.i
  LastVisRow.i
  FrstVisCol.i
  LastVisCol.i
  
  ; Visual on screen - Dynamic fields control drawing/scrolling/... 
  ; Area-Row 0 : will show Col-Headers
  ; Area-Col 0 : will show Row-Headers
  
  FrozenCol.i                     ; last fixed col - cant scroll
  FrozenRow.i                     ; last fixed row - cant scroll
  
  List LstAreaCol._MyGrid_AreaCol_Type() ; list of all defined col-screen-areas
  List LstAreaRow._MyGrid_AreaRow_Type() ; list of all defined row-screen-areas
  
  Map DicAreaOfRow.i()            ; area associtaed with that Row
  Map DicAreaOfCol.i()            ; area associtaed with that Col
  
  MoveStatus.i                    ; what the mouse-move is doing right now
  DownX.i
  DownY.i
  DownAreaRow.i
  DownAreaCol.i
  
  Color_Line.i                    ; grid-line color
  Color_Background.i              ; grey-area color
  Color_FocusBack.i               ; while editing cells
  Color_FocusBorder.i             ; 
  Color_BlockBack.i               ; block highlight
  
  ; Block ... one block only, Block starts in (Row, Col) and ends in cell (Row2, Col2)
  Row2.i                          ; end cell can be above/before start cell !
  Col2.i                          ; 
  BlockX.i
  BlockY.i
  BlockW.i
  BlockH.i
  
  ChangedCol.i                    ; last changed cell via user-editing
  ChangedRow.i
  ChangedTxt.s                    ; last-changed cell old text
  
  ClickedCol.i                    ; last clicked cell via
  ClickedRow.i
  
  ; Styles control the Visual display of all Grid-elements
  List LstStyle._MyGrid_CellStyle_Type()     ; this list is never empty! Contains one element: 1st style, that apply to the whole grid by default
  Map  DicStyle.i()                   ; Key= "Row:Col" and Value= index of attached style
  
  Style_Data_Data.i
  Style_Any_Data.i
  Style_Data_Any.i
  Style_Any_Any.i
  
  ; cell span/ merged cells ---> one multi-cell
  List LstMulti._MyGrid_MultiCell_Type()
  
  NoRedraw.i                          ; True/False - if true then we stop continuous redrawing
  
  DeltaX.i                        ; will be used to relativise absolute X,Y
  DeltaY.i
  
EndStructure
;}

;--- Helpers
Procedure.i MySplitString(s.s, multiCharSep.s, Array a.s(1))
  ; last substring is not necesseraly followed by a char-sep
  Protected count, i, soc, lnStr,lnBStr, lnSep,lnBSep, ss, ee
  
  soc     = SizeOf(Character)
  lnSep   = Len(multiCharSep) :   lnBSep  = lnSep * soc
  lnStr   = Len(s)            :   lnBStr  = lnStr * soc
  If lnStr <= 0               :   ProcedureReturn 0       : EndIf
  
  count   = CountString(s,multiCharSep)
  If count <= 0
    Dim a(1) : a(1) = s : ProcedureReturn 1
  EndIf
  
  If Right(s,lnSep) <> multiCharSep : count + 1 : EndIf 
  
  Dim a(count) ; a(0) is ignored
  
  i = 1: ss = 0: ee = 0
  While ee < lnBStr
    If CompareMemory(@s + ee, @multiCharSep, lnBSep)
      a(i) = PeekS(@s + ss, (ee-ss)/soc)
      ss = ee + lnBSep: ee = ss: i+1
    Else
      ee + soc
    EndIf
  Wend
  
  If i < count+1: a(count) = PeekS(@s + ss, (ee-ss)/soc) : EndIf
  ProcedureReturn count ;return count of substrings
  
EndProcedure
Procedure.i BlendColor(Color1, Color2, Scale=50)
  Protected R1, G1, B1, R2, G2, B2, Scl.f = Scale/100
  
  R1 = Red(Color1): G1 = Green(Color1): B1 = Blue(Color1)
  R2 = Red(Color2): G2 = Green(Color2): B2 = Blue(Color2)
  ProcedureReturn RGB((R1*Scl) + (R2 * (1-Scl)), (G1*Scl) + (G2 * (1-Scl)), (B1*Scl) + (B2 * (1-Scl)))
  
EndProcedure
Procedure.i PosTextToWidth(Txt.s, Width)
  ; return under current Drawing, the left part of Txt that has a TextWidth() <= Width 
  Protected w, w0, e0, e1, e = Len(Txt)
  
  Repeat
    w = TextWidth( Mid(Txt, e0+1, e-e0) )
    If (w0 + w) <= Width
      e0 = e : e = e1 : w0 = w0 + w   ; e0 succeeded so far
    Else
      e1 = e                          ; e1 denotes last failure
      e  = e0 + ((e-e0)/2)
    EndIf
    If e0 >= e : Break : EndIf
    
  ForEver
  ProcedureReturn e0
  
EndProcedure
Procedure.i MyDrawText(txt.s,x,y,width,height,algn=0,wrap=0)
  Protected x1,x2,y1,y2, mx,aw,my,ah, cc.s
  Protected i,j,n,w,h,x0,w0,h0,lines
  
  mx = #MyGrid_Text_MarginX      ; default X-horizontal margin left/right
  my = #MyGrid_Text_MarginY      ; default Y-vertical margin up/down
  aw = width  - 2*mx          ; actual given width for drawing
  ah = height - 2*my          ; actual given height for drawing
  n = Len(txt)
  
  If (aw <= 0) Or (ah <= 0) Or (n <= 0) : ProcedureReturn : EndIf
  
  w = TextWidth(txt)  
  h = TextHeight(txt)
  If ah < h : ProcedureReturn : EndIf
  
  If w <= aw 
    ; we have enough room to write straight forward ...
    If algn = #MyGrid_Align_Left
      x1 = x + mx
    ElseIf algn = #MyGrid_Align_Right
      x1 = x + mx + (aw - w)
    ElseIf algn = #MyGrid_Align_Center
      x1 = x + mx + ((aw - w)/2)
    EndIf
    y1 = y + my + ((ah - h)/2)
    DrawText(x1,y1,txt)
    ProcedureReturn
  Else
    x1 = x + mx : x2 = x1 + aw
    If wrap = #False
      DrawText(x1,y1, Mid(txt, 1, PosTextToWidth(txt, aw)))
    Else
      ; we need to wrap text on another line(s) ... when wrapping we do not consider alignment (for now!)
      Protected drawnSome, iWrd,nWrd, Dim tWrd.s(0)
      
      y1 = y + my : y2 = y + height - my
      lines = Round(w/aw,#PB_Round_Up)
      If ah - (lines*h) > 0
        y1 = y1 + ((ah - (lines*h))/2)
      EndIf
      
      nWrd = MySplitString(txt, " ", tWrd())
      
      iWrd = 1
      Repeat
        If iWrd > nWrd : Break : EndIf
        If iWrd > 1 : x1 = DrawText(x1,y1," ") : EndIf
        ; 3 cases
        ; 1. enough room in avaliable width on current line
        ; 2. no enough room but a new line can hold the whole word
        ; 3. even a new line cant hold the word we split it on many lines
        w = TextWidth(tWrd(iWrd))
        If w <= (x2-x1)
          x1 = DrawText(x1,y1,tWrd(iWrd)) : drawnSome = 1
          iWrd = iWrd + 1
        Else
          ; move to a new line
          If drawnSome
            y1 = y1 + h : x1 = x + mx
          EndIf
          If y1+h > y2 : Break : EndIf
          If w <= aw
            x1 = DrawText(x1,y1,tWrd(iWrd)) : drawnSome = 1
            iWrd = iWrd + 1
          Else
            n = PosTextToWidth(tWrd(iWrd), x2-x1)
            If n > 0
              x1 = DrawText(x1,y1, Mid(tWrd(iWrd),1,n)) : drawnSome = 1
              tWrd(iWrd) = Mid(tWrd(iWrd),n+1)
            Else
              iWrd = iWrd + 1
            EndIf
          EndIf
        EndIf
        If y1+h > y2 : Break : EndIf
      ForEver 
    EndIf
  EndIf
  
EndProcedure     
Procedure.i DrawCheckBox(x,y,w,h, boxWidth, checked, borderColor)
  ; draw a check-box /(x,y,w,h) in the area given for drawing checkbox... assumes a StartDrawing!
  Protected ww,hh, x0,y0,xa,ya,xb,yb,xc,yc
  
  ww = boxWidth : hh = boxWidth
  If ww <= w And hh <= h 
    x0 = x + ((w - ww) / 2)
    y0 = y + ((h - hh) / 2)
    DrawingMode(#PB_2DDrawing_Default)
    Box(x0  ,y0  ,ww  ,hh  ,borderColor)
    Box(x0+1,y0+1,ww-2,hh-2,$D4D4D4)
    Box(x0+2,y0+2,ww-4,hh-4,$FFFFFF)
    
    If checked
      xb = x0 + (ww / 2) - 1  :   yb = y0 + hh - 5
      xa = x0 + 4             :   ya = yb - xb + xa
      xc = x0 + ww - 4        :   yc = yb + xb - xc
      
      FrontColor($12A43A) ; color of the check mark
      LineXY(xb,yb  ,xa,ya  ) :   LineXY(xb,yb  ,xc,yc  )
      LineXY(xb,yb-1,xa,ya-1) :   LineXY(xb,yb-1,xc,yc-1) ; move up by 1
      LineXY(xb,yb-2,xa,ya-2) :   LineXY(xb,yb-2,xc,yc-2) ; move up by 2
    EndIf
  EndIf
  
EndProcedure

Procedure.i DrawCombo(x,y,w,h)
  ; draw a combo-box-arrow ... assumes a StartDrawing!
  Protected inColor = RGB(87, 87, 87) ;$34AD1B ;$666666
  Protected xx,yy,ww,hh   ; box coord and dimensions
  
  ww = 16
  hh = 3
  If ww < w And hh < h 
    xx = x + w - ww
    DrawingMode(#PB_2DDrawing_Gradient)
    BackColor(RGB(224, 226, 226)) : FrontColor(RGB(201, 201, 201)) : LinearGradient(X,Y,X,Y+H/2)
    ;BackColor($FFFFFF) : FrontColor($B5B5B5) : LinearGradient(X,Y,X,Y+H/2)
    Box(xx+3,y+3,ww-5,h -5)
    
    DrawingMode(#PB_2DDrawing_Default)
    ;Box(xx+3,y+3,ww-5,h -5)
    xx = xx + 3 : ww = ww - 5: yy = (y+2) + (h-8)/2
    LineXY(xx+ 3,yy+ 1,xx+ww-4,yy+ 1,inColor)
    LineXY(xx+ 4,yy+ 2,xx+ww-5,yy+ 2,inColor)
    LineXY(xx+ 5,yy+ 3,xx+ww-6,yy+ 3,inColor)
  EndIf
  
EndProcedure
Procedure.i DrawButton(x,y,w,h,bClr)
  ; draw a clickable button
  
  DrawingMode(#PB_2DDrawing_Default)
  Box(x,y,w,h,#White)
  BackColor(BlendColor(RGB(255, 255, 255),bClr,70))
  FrontColor(bClr)
  LinearGradient(x,y,x,y+h)
  DrawingMode(#PB_2DDrawing_Gradient)
  Box(x+1,y+1,w-2,h-2)
  ;RoundBox(x,y,w,h,4,4)
  ;RoundBox(x+2,y+2,w-4,h-4,2,2)
  
  
EndProcedure
Macro       BlocksHaveIntersection(AR1,AR2,AC1,AC2, BR1,BR2,BC1,BC2)
  ; return true if there are cells in common between the two blocks A and B
  ; A is defined by AR1,AR2,AC1,AC2 .... R1 <= R2 and C1 <= C2
  ; B is defined by BR1,BR2,BC1,BC2
  
  ((AR2 >= BR1) And (BR2 >= AR1) And (AC2 >= BC1) And (BC2 >= AC1))
  
EndMacro

;------------- Declared Subs -----------------------
Declare.i _MyGrid_GridToScrolls(*mg._MyGrid_Type)
Declare.i _MyGrid_AdjustScrolls(*mg._MyGrid_Type)
;---------------------------------------------------

;--- Row >= 0 , Col >= 0  (Row = 0 or Col = 0 ---> header)
Macro _MyGrid_CellIndex(m, Row, Col)
  ((m\Cols+1) * Row) + Col
EndMacro
Macro _MyGrid_SetCellText(m, Row, Col, Txt)
  m\gData(_MyGrid_CellIndex(m, Row, Col)) = Txt
EndMacro
Macro _MyGrid_SetCellTextEvent(m, Row, Col, Txt)
  ; used when cell content has changed via user input ... post event: #MyGrid_Event_Change
  m\ChangedCol = Col
  m\ChangedRow = Row
  m\ChangedTxt = m\gData(_MyGrid_CellIndex(m, Row, Col))
  m\gData(_MyGrid_CellIndex(m, Row, Col)) = Txt
  PostEvent(#MyGrid_Event_Change, m\Window, m\Gadget) ; throw an event in the loop
EndMacro
Macro _MyGrid_GetCellText(m, Row, Col)
  m\gData(_MyGrid_CellIndex(m, Row, Col))
EndMacro
Macro _MyGrid_IsValidRow( m, Row)
  ((Row >= 0) And (Row <= m\Rows))
EndMacro
Macro _MyGrid_IsValidCol( m, Col)
  ((Col >= 0) And (Col <= m\Cols))
EndMacro

Macro _MyGrid_IsValidCell(m, Row, Col)
  ((Row >= 0) And (Row <= m\Rows) And (Col >= 0) And (Col <= m\Cols))
EndMacro
Macro _MyGrid_ResetBlock(m)
  m\Row2 = 0 : m\Col2 = 0 : m\BlockX = 0 : m\BlockY = 0 : m\BlockW = 0 : m\BlockH = 0
EndMacro
Macro _MyGrid_HasBlock(m)
  ((m\Row2 > 0) And (m\Col2 > 0) And (m\Row <> m\Row2 Or m\Col <> m\Col2))
EndMacro
Macro _MyGrid_ResetDownClick(m)
  m\DownX = 0 : m\DownY = 0 : m\DownAreaRow = -1 : m\DownAreaCol = -1
EndMacro

Procedure.i _MyGrid_LoadInEditCombo(*mg._MyGrid_Type, Style)
  
  If *mg\CmbEditCurStyle = Style                      : ProcedureReturn : EndIf
  If Style < 0 Or Style >= ListSize(*mg\LstStyle())   : ProcedureReturn : EndIf
  
  SelectElement(*mg\LstStyle() , Style)
  ClearGadgetItems(*mg\CmbEdit)
  
  ForEach *mg\LstStyle()\Item()
    AddGadgetItem(*mg\CmbEdit, -1, *mg\LstStyle()\Item())
  Next
  *mg\CmbEditCurStyle = Style
  
EndProcedure

;--- GRow , GCol Generic row/col
Macro _MyGrid_IsValidGenericRow( m, GRow)
  ((GRow >= 0 And GRow <= m\Rows) Or (GRow = #MyGrid_RC_Any) Or (GRow = #MyGrid_RC_Data))
EndMacro
Macro _MyGrid_IsValidGenericCol( m, GCol)
  ((GCol >= 0 And GCol <= m\Cols) Or (GCol = #MyGrid_RC_Any) Or (GCol = #MyGrid_RC_Data))
EndMacro

Procedure.i __MyGrid_SelectStyle( *mg._MyGrid_Type, Row, Col)
  ; no return value - points in the list of styles at the right one!
  ; R >= 0 can be masked by R, Data,Any ... a cell can be masked by upto 9 styles
  ;
  FirstElement(*mg\LstStyle())
  If ListSize(*mg\LstStyle()) > 1
    If FindMapElement(*mg\DicStyle(), Str(Row) + ":" + Str(Col))
      SelectElement(*mg\LstStyle() , *mg\DicStyle()) : ProcedureReturn
    EndIf
    ; --- any parent style in that order: RD,DC,RA,AC,  DD,DA,AD,AA
    If (Col > 0) And FindMapElement(*mg\DicStyle(), Str(Row) + ":" + Str(#MyGrid_RC_Data))
      SelectElement(*mg\LstStyle() , *mg\DicStyle()) : ProcedureReturn
    EndIf
    If (Row > 0) And FindMapElement(*mg\DicStyle(), Str(#MyGrid_RC_Data) + ":" + Str(Col))
      SelectElement(*mg\LstStyle() , *mg\DicStyle()) : ProcedureReturn
    EndIf
    If (Col >= 0) And FindMapElement(*mg\DicStyle(), Str(Row) + ":" + Str(#MyGrid_RC_Any))
      SelectElement(*mg\LstStyle() , *mg\DicStyle()) : ProcedureReturn
    EndIf
    If (Row >= 0) And FindMapElement(*mg\DicStyle(), Str(#MyGrid_RC_Any) + ":" + Str(Col))
      SelectElement(*mg\LstStyle() , *mg\DicStyle()) : ProcedureReturn
    EndIf
    
    If (Col > 0) And (Row > 0) And (*mg\Style_Data_Data >= 0)
      SelectElement(*mg\LstStyle() , *mg\Style_Data_Data) : ProcedureReturn
    EndIf
    If (Col > 0) And (Row >= 0) And (*mg\Style_Data_Any >= 0)
      SelectElement(*mg\LstStyle() , *mg\Style_Data_Any) : ProcedureReturn
    EndIf
    If (Col >= 0) And (Row > 0) And (*mg\Style_Any_Data >= 0)
      SelectElement(*mg\LstStyle() , *mg\Style_Any_Data) : ProcedureReturn
    EndIf
    If (Col >= 0) And (Row >= 0) And (*mg\Style_Any_Any >= 0)
      SelectElement(*mg\LstStyle() , *mg\Style_Any_Any) : ProcedureReturn
    EndIf
  EndIf
  
EndProcedure

Procedure.i _MyGrid_MultiOfCell(*mg._MyGrid_Type, Row, Col)
  
  ForEach *mg\LstMulti()
    If Row < *mg\LstMulti()\R1 Or *mg\LstMulti()\R2 < Row : Continue : EndIf
    If Col < *mg\LstMulti()\C1 Or *mg\LstMulti()\C2 < Col : Continue : EndIf
    ProcedureReturn ListIndex(*mg\LstMulti())
  Next
  ProcedureReturn -1
  
EndProcedure

Procedure.i _MyGrid_ChangeColWidth(*mg._MyGrid_Type, GCol, Width, AdjustScrolls = #True)
  Protected i
  
  If Not _MyGrid_IsValidGenericCol(*mg, GCol) : ProcedureReturn : EndIf
  
  If Width < #MyGrid_Text_MarginX And Width <> -1 : Width = 0 : EndIf
  
  If GCol >= 0
    *mg\ColWidth(GCol) = Width
    _MyGrid_AdjustScrolls(*mg)
    ProcedureReturn
  EndIf
  
  If GCol = #MyGrid_RC_Any
    *mg\ColWidth(0) = Width
  EndIf
  
  If GCol = #MyGrid_RC_Data Or GCol = #MyGrid_RC_Any
    For i = 1 To *mg\Cols
      *mg\ColWidth(i) = Width
    Next
  EndIf
  
  If AdjustScrolls : _MyGrid_AdjustScrolls(*mg) : EndIf
  
EndProcedure
Procedure.i _MyGrid_ChangeRowHeight(*mg._MyGrid_Type, GRow, Height, AdjustScrolls = #True)
  Protected i
  
  If Not _MyGrid_IsValidGenericRow(*mg, GRow) : ProcedureReturn : EndIf
  
  If Height < #MyGrid_Text_MarginY And Height <> -1 : Height = 0 : EndIf
  
  If GRow >= 0
    *mg\RowHeight(GRow) = Height
    _MyGrid_AdjustScrolls(*mg)
    ProcedureReturn
  EndIf
  
  If GRow = #MyGrid_RC_Any
    *mg\RowHeight(0) = Height
  EndIf
  
  If GRow = #MyGrid_RC_Data Or GRow = #MyGrid_RC_Any
    For i = 1 To *mg\Rows
      *mg\RowHeight(i) = Height
    Next
  EndIf
  
  If AdjustScrolls : _MyGrid_AdjustScrolls(*mg) : EndIf
  
EndProcedure


;---------- Areas & coordinates
; Row and Col are index in data-grid
; X, Y are coordinates on screen (visibe part of the grid)

;------------------------------

Procedure.i _MyGrid_AddAreaRow(*mg._MyGrid_Type, Row, Y, H)
  
  AddElement( *mg\LstAreaRow() )
  *mg\LstAreaRow()\Y     = Y
  *mg\LstAreaRow()\Row   = Row
  *mg\LstAreaRow()\Height= H
  *mg\DicAreaOfRow(Str(Row)) = ListIndex( *mg\LstAreaRow() )
  
EndProcedure
Procedure.i _MyGrid_AddAreaCol(*mg._MyGrid_Type, Col, X, W)
  
  AddElement( *mg\LstAreaCol() )
  *mg\LstAreaCol()\X     = X
  *mg\LstAreaCol()\Col   = Col
  *mg\LstAreaCol()\Width = W
  *mg\DicAreaOfCol(Str(Col)) = ListIndex( *mg\LstAreaCol() )
  
EndProcedure

;------------------------------
Procedure.i _MyGrid_RefreshCounters(*mg._MyGrid_Type)
  ; getting first/last Top/Vis Rows/Cols
  Protected i, avl, act
  
  *mg\FrstVisRow = 0
  For i = 1 To *mg\Rows
    If *mg\RowHeight(i) > 0 : *mg\FrstVisRow = i : Break : EndIf
  Next 
  *mg\LastVisRow  = 0
  For i = *mg\Rows To 1 Step -1
    If *mg\RowHeight(i) > 0 : *mg\LastVisRow  = i : Break : EndIf
  Next 
  
  *mg\FrstTopRow = 0
  For i = *mg\FrozenRow + 1 To *mg\Rows
    If *mg\RowHeight(i) > 0 : *mg\FrstTopRow = i : Break : EndIf
  Next
  *mg\LastTopRow = *mg\FrstTopRow
  
  avl = *mg\GadgetH
  For i = 0 To *mg\FrozenRow
    If *mg\RowHeight(i) > 0 : avl = avl - (*mg\RowHeight(i) - 1) : EndIf
  Next
  If avl > 0
    act = 0
    For i = *mg\Rows To *mg\FrstTopRow Step -1
      If *mg\RowHeight(i) > 0
        If act + (*mg\RowHeight(i) -1) > avl : Break : EndIf
        act = act + (*mg\RowHeight(i) - 1)
        *mg\LastTopRow = i
      EndIf
    Next
  EndIf
  If *mg\TopRow < *mg\FrstTopRow : *mg\TopRow = *mg\FrstTopRow : EndIf
  If *mg\TopRow > *mg\LastTopRow : *mg\TopRow = *mg\LastTopRow : EndIf
  
  ; ---- Cols
  *mg\FrstVisCol = 0
  For i = 1 To *mg\Cols
    If *mg\ColWidth(i) > 0 : *mg\FrstVisCol = i : Break : EndIf
  Next 
  *mg\LastVisCol = 0
  For i = *mg\Cols To 1 Step -1
    If *mg\ColWidth(i) > 0 : *mg\LastVisCol  = i : Break : EndIf
  Next 
  
  *mg\FrstTopCol = 0
  For i = *mg\FrozenCol + 1 To *mg\Cols
    If *mg\ColWidth(i) > 0 : *mg\FrstTopCol = i : Break : EndIf
  Next
  *mg\LastTopCol = *mg\FrstTopCol
  
  avl = *mg\GadgetW
  For i = 0 To *mg\FrozenCol
    If *mg\ColWidth(i) > 0 : avl = avl - (*mg\ColWidth(i) - 1) : EndIf
  Next
  If avl > 0
    act = 0
    For i = *mg\Cols To *mg\FrstTopCol Step -1
      If *mg\ColWidth(i) > 0
        If act + (*mg\ColWidth(i) -1) > avl : Break : EndIf
        act = act + (*mg\ColWidth(i) - 1)
        *mg\LastTopCol = i
      EndIf
    Next
  EndIf
  If *mg\TopCol < *mg\FrstTopCol : *mg\TopCol = *mg\FrstTopCol : EndIf
  If *mg\TopCol > *mg\LastTopCol : *mg\TopCol = *mg\LastTopCol : EndIf
  
EndProcedure

Procedure.i _MyGrid_BuildAreas(*mg._MyGrid_Type)
  ; Builds screen-areas Rows and Cols
  ; based on: TopRow , TopCol , visible-rows, visisble-cols
  Protected i,x,y,w,h,iCol,iRow,nCols,nRows, avl, act
  
  ; initializing all non-hidden Rows, Cols to non-visible
  ClearMap(*mg\DicAreaOfRow())
  ClearMap(*mg\DicAreaOfCol())
  
  ClearList( *mg\LstAreaRow() )
  ClearList( *mg\LstAreaCol() )
  
  _MyGrid_AddAreaRow(*mg, 0, 0, *mg\RowHeight(0))
  _MyGrid_AddAreaCol(*mg, 0, 0, *mg\ColWidth(0))
  
  ; -- building row-areas
  ; adjusts TopRow [ FrozenRow+1 ... Rows ]
  If *mg\TopRow <= *mg\FrozenRow  : *mg\TopRow = *mg\FrozenRow + 1 : EndIf
  Repeat
    If *mg\TopRow  > *mg\Rows
      *mg\TopRow = 0
      Break
    EndIf
    If *mg\RowHeight(*mg\TopRow) > 0 : Break : EndIf
    *mg\TopRow = *mg\TopRow + 1
  ForEver
  
  y = *mg\RowHeight(0) - 1 : If y < 0 : y = 0 : EndIf
  
  For iRow = 1 To *mg\Rows
    
    If y >= *mg\GadgetH : Break : EndIf
    
    h = *mg\RowHeight(iRow)
    If h > 0
      ; skip rows that are ] FrozenRow , TopRow [
      If iRow > *mg\FrozenRow And iRow < *mg\TopRow : Continue : EndIf
      _MyGrid_AddAreaRow(*mg, iRow, y, h)
      y = y + h - 1
    EndIf
  Next iRow
  
  ; -- building col-areas
  ; adjusts TopCol [ FrozenCol+1 ... Cols ]
  If *mg\TopCol <= *mg\FrozenCol  : *mg\TopCol = *mg\FrozenCol + 1 : EndIf
  Repeat
    If *mg\TopCol  > *mg\Cols
      *mg\TopCol = 0
      Break
    EndIf
    If *mg\ColWidth(*mg\TopCol) > 0 : Break : EndIf
    *mg\TopCol = *mg\TopCol + 1
  ForEver
  
  x = *mg\ColWidth(0) - 1 : If x < 0 : x = 0 : EndIf
  
  For iCol = 1 To *mg\Cols
    
    If x >= *mg\GadgetW : Break : EndIf
    
    w = *mg\ColWidth(iCol)
    If w > 0
      ; skip cols that are ] FrozenCol , TopCol [
      If iCol > *mg\FrozenCol And iCol < *mg\TopCol : Continue : EndIf
      _MyGrid_AddAreaCol(*mg, iCol, x, w)
      x = x + w - 1
    EndIf
  Next iCol
  
EndProcedure
;------------------------------

Procedure.i _MyGrid_AreaRow_Of_Y(*mg._MyGrid_Type, y)
  
  ForEach *mg\LstAreaRow()
    If y <= *mg\LstAreaRow()\Y                            : Continue : EndIf
    If y >  *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height  : Continue : EndIf
    ProcedureReturn ListIndex(*mg\LstAreaRow())
  Next
  ProcedureReturn -1      ; outside any area!
  
EndProcedure
Procedure.i _MyGrid_AreaCol_Of_X(*mg._MyGrid_Type, x)
  
  ForEach *mg\LstAreaCol()
    If x <= *mg\LstAreaCol()\X                            : Continue : EndIf
    If x >  *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width   : Continue : EndIf
    ProcedureReturn ListIndex(*mg\LstAreaCol())
  Next
  ProcedureReturn -1      ; outside any area!
  
EndProcedure

Procedure.i _MyGrid_Row_Of_Y(*mg._MyGrid_Type, y)
  Protected  area = _MyGrid_AreaRow_Of_Y(*mg, y)
  
  If area >= 0
    SelectElement(*mg\LstAreaRow(), area)
    ProcedureReturn *mg\LstAreaRow()\Row
  EndIf
  
  ProcedureReturn -1
  
EndProcedure
Procedure.i _MyGrid_Col_Of_X(*mg._MyGrid_Type, x)
  Protected  area = _MyGrid_AreaCol_Of_X(*mg, x)
  
  If area >= 0
    SelectElement(*mg\LstAreaCol(), area)
    ProcedureReturn *mg\LstAreaCol()\Col
  EndIf
  
  ProcedureReturn -1
  
EndProcedure

Procedure.i _MyGrid_Area_Of_Row(*mg._MyGrid_Type, Row)
  
  If FindMapElement( *mg\DicAreaOfRow() , Str(Row))
    ProcedureReturn *mg\DicAreaOfRow()
  EndIf
  
  ProcedureReturn -1      ; row not visible
  
EndProcedure
Procedure.i _MyGrid_Area_Of_Col(*mg._MyGrid_Type, Col)
  
  If FindMapElement( *mg\DicAreaOfCol() , Str(Col))
    ProcedureReturn *mg\DicAreaOfCol()
  EndIf
  
  ProcedureReturn -1      ; col not visible
  
EndProcedure

Procedure.i _MyGrid_AreaResizeCol(*mg._MyGrid_Type, x, y)
  ; return the col-area affected by user-resize starting at (x,y)
  FirstElement(*mg\LstAreaRow())
  If y > *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height
    ProcedureReturn -1
  EndIf
  
  ForEach *mg\LstAreaCol()
    If Abs(*mg\LstAreaCol()\X + *mg\LstAreaCol()\Width - x) <= #MyGrid_ColSep_Margin
      ProcedureReturn ListIndex(*mg\LstAreaCol())
    EndIf
  Next
  ProcedureReturn -1
  
EndProcedure
Procedure.i _MyGrid_AreaResizeRow(*mg._MyGrid_Type, x, y)
  ; return the row-area affected by user-resize starting at (x,y)
  FirstElement(*mg\LstAreaCol())
  If x > *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width
    ProcedureReturn -1
  EndIf
  
  ForEach *mg\LstAreaRow()
    If Abs(*mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height - y) <= #MyGrid_RowSep_Margin
      ProcedureReturn ListIndex(*mg\LstAreaRow())
    EndIf
  Next
  ProcedureReturn -1
  
EndProcedure

Macro       _MyGrid_OverCellArea(m, x, y)
  ( _MyGrid_AreaRow_Of_Y(m, y) > 0 And _MyGrid_AreaCol_Of_X(m, x) > 0 )
EndMacro
Macro       _MyGrid_OverResizeCol(m, x, y)
  ( _MyGrid_AreaResizeCol(m, x, y) >= 0 )
EndMacro
Macro       _MyGrid_OverResizeRow(m, x, y)
  ( _MyGrid_AreaResizeRow(m, x, y) >= 0 )
EndMacro
Macro       _MyGrid_OverBlock(m, x, y)
  ( m\BlockX < x And x <= (m\BlockX + m\BlockW) And m\BlockY < y And y <= (m\BlockY + m\BlockH) )
EndMacro

Procedure.i _MyGrid_ChangeMouse(*mg._MyGrid_Type, x, y)
  Protected r,c,stl
  
  *mg\DeltaX = WindowMouseX(*mg\Window) - x
  *mg\DeltaY = WindowMouseY(*mg\Window) - y
  
  If _MyGrid_OverResizeCol(*mg, x, y)
    SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_LeftRight)
    ProcedureReturn
  EndIf
  
  If _MyGrid_OverResizeRow(*mg, x, y)
    SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_UpDown)
    ProcedureReturn
  EndIf
  
  If _MyGrid_OverCellArea(*mg, x, y)
    r = _MyGrid_Row_Of_Y(*mg, y)
    c = _MyGrid_Col_Of_X(*mg, x)
    __MyGrid_SelectStyle(*mg, r, c)
    If *mg\LstStyle()\CellType <> #MyGrid_CellType_Normal
      SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
    Else
      SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_Cross)  
    EndIf
    ProcedureReturn
  EndIf
  SetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor,#PB_Cursor_Default)
  
EndProcedure
Procedure.i _MyGrid_RectCoord(*mg._MyGrid_Type, R1,C1,R2,C2,*bc._MyGrid_Rectangle_Type)
  ; return in *bc its (X,Y,W,H) built from block [(R1,C1) ... (R2,C2)]
  Protected X,Y,W,H, ar,ac, iR,iC
  
  X = -1 : Y = -1 : H = 0 : W = 0
  If R1 > R2 : Swap R1 , R2 : EndIf
  If C1 > C2 : Swap C1 , C2 : EndIf
  
  PushListPosition(*mg\LstAreaRow())
  For iR = R1 To R2
    ar = _MyGrid_Area_Of_Row(*mg, iR)
    If ar >= 0
      SelectElement(*mg\LstAreaRow() , ar)
      If Y < 0 : Y = *mg\LstAreaRow()\Y : EndIf
      H = H + *mg\LstAreaRow()\Height - 1
    EndIf
    If Y + H > *mg\GadgetH : Break : EndIf
  Next
  PopListPosition(*mg\LstAreaRow())
  
  PushListPosition(*mg\LstAreaCol())
  For iC = C1 To C2
    ac = _MyGrid_Area_Of_Col(*mg, iC)
    If ac >= 0
      SelectElement(*mg\LstAreaCol() , ac)
      If X < 0 : X = *mg\LstAreaCol()\X : EndIf
      W = W + *mg\LstAreaCol()\Width - 1
    EndIf
    If X + W > *mg\GadgetW : Break : EndIf
  Next
  PopListPosition(*mg\LstAreaCol())
  
  If H > 0 And W > 0
    *bc\X = X
    *bc\Y = Y
    *bc\W = W+1
    *bc\H = H+1
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
  
EndProcedure
Procedure.i _MyGrid_BlockSize(*mg._MyGrid_Type)
  Protected bc._MyGrid_Rectangle_Type
  
  _MyGrid_RectCoord(*mg, *mg\Row, *mg\Col, *mg\Row2, *mg\Col2, @bc)
  *mg\BlockX = bc\X
  *mg\BlockY = bc\Y
  *mg\BlockW = bc\W
  *mg\BlockH = bc\H
  
EndProcedure

Procedure.i _MyGrid_StartBlock(*mg._MyGrid_Type, Row1 = -1, Col1 = -1, Row2 = -1, Col2 = -1)
  ; start a new block ... reset existing one if any 
  Protected R1=Row1, C1=Col1, R2=Row2, C2=Col2, bc._MyGrid_Rectangle_Type
  
  If _MyGrid_HasBlock(*mg)
    _MyGrid_ResetBlock(*mg)
  EndIf
  
  If R1 = -1 : R1 = *mg\Row : EndIf
  If R2 = -1 : R2 = *mg\Row : EndIf
  If C1 = -1 : C1 = *mg\Col : EndIf
  If C2 = -1 : C2 = *mg\Col : EndIf
  
  If Not _MyGrid_IsValidCell(*mg, R1, C1) : ProcedureReturn : EndIf
  If Not _MyGrid_IsValidCell(*mg, R2, C2) : ProcedureReturn : EndIf
  
  *mg\Row  = R1 : *mg\Col  = C1
  *mg\Row2 = R2 : *mg\Col2 = C2
  _MyGrid_BlockSize(*mg)
  
EndProcedure

;-------------------------------------------------------------------------------------------- 
;--- Drawing
;-------------------------------------------------------------------------------------------- 
Procedure.i __MyGrid_DrawSingleCell(*mg._MyGrid_Type, Row, Col)
  ; basic routine called by higher ones:   .......... assumes StartDrawing()
  ; _MyGrid_DrawCurrentCell()
  ; _MyGrid_Draw()
  Protected checked, wrd.s, SBColor, SFColor, SAlign, SFont, SType, SGrdnt
  Protected ar,ac,X,Y,W,H
  
  ar = _MyGrid_Area_Of_Row(*mg, Row)
  ac = _MyGrid_Area_Of_Col(*mg, Col)
  If ar < 0 Or ac < 0 : ProcedureReturn : EndIf
  
  SelectElement(*mg\LstAreaCol(), ac)
  SelectElement(*mg\LstAreaRow(), ar)
  X  = *mg\LstAreaCol()\X
  W  = *mg\LstAreaCol()\Width
  Y  = *mg\LstAreaRow()\Y
  H  = *mg\LstAreaRow()\Height
  
  __MyGrid_SelectStyle(*mg, Row, Col)
  SBColor = *mg\LstStyle()\BackColor
  SFColor = *mg\LstStyle()\ForeColor
  SAlign  = *mg\LstStyle()\Aling
  SFont   = *mg\LstStyle()\Font
  SType   = *mg\LstStyle()\CellType
  SGrdnt  = *mg\LstStyle()\Gradient
  
  wrd = _MyGrid_GetCellText(*mg, Row, Col)
  If SGrdnt > 0
    DrawingMode(#PB_2DDrawing_Gradient)
    BackColor($F0F0F0) : FrontColor(SBColor) : LinearGradient(X,Y,X,Y+H/2)
    Box(X,Y,W,H)
  Else
    DrawingMode(#PB_2DDrawing_Default)
    Box(X,Y,W,H,SBColor)
  EndIf
  
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(X,Y,W,H, *mg\Color_Line)
  
  Select SType
      
    Case #MyGrid_CellType_Normal
      
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W,H, SAlign, *mg\WrapText)
      
    Case #MyGrid_CellType_Checkbox
      checked = Val(wrd)
      DrawingMode(#PB_2DDrawing_Default)
      DrawCheckBox(X,Y,W,H, #MyGrid_CheckBox_Width, checked, #MyGrid_CheckBox_Color)
      
    Case #MyGrid_CellType_Button
      ;DrawButton(X+2,Y+2,W-4,H-4,SBColor)
      DrawButton(X+1,Y+1,W-2,H-2,SBColor)
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W,H, SAlign, *mg\WrapText)
      
    Case #MyGrid_CellType_Combo
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W-16,H, SAlign, *mg\WrapText)
      
      DrawingMode(#PB_2DDrawing_Default)
      DrawCombo(X,Y,W,H)
      
  EndSelect
  
EndProcedure
Procedure.i __MyGrid_DrawMultiCell(*mg._MyGrid_Type, Multi)
  ; basic routine called by higher ones:   .......... assumes StartDrawing()
  Protected checked, wrd.s, SBColor, SFColor, SAlign, SFont, SType, SGrdnt
  Protected bc._MyGrid_Rectangle_Type, mlt = -1, Row, Col, X,Y,W,H
  
  SelectElement(*mg\LstMulti(), Multi)
  If Not _MyGrid_RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
    ProcedureReturn
  EndIf
  
  X = bc\X
  Y = bc\Y
  W = bc\W
  H = bc\H
  
  Row = *mg\LstMulti()\R1
  Col = *mg\LstMulti()\C1
  
  __MyGrid_SelectStyle(*mg, Row, Col)
  SBColor = *mg\LstStyle()\BackColor
  SFColor = *mg\LstStyle()\ForeColor
  SAlign  = *mg\LstStyle()\Aling
  SFont   = *mg\LstStyle()\Font
  SType   = *mg\LstStyle()\CellType
  SGrdnt  = *mg\LstStyle()\Gradient
  
  wrd = _MyGrid_GetCellText(*mg, Row, Col)
  If SGrdnt > 0
    DrawingMode(#PB_2DDrawing_Gradient)
    BackColor($F0F0F0) : FrontColor(SBColor) : LinearGradient(X,Y,X,Y+H/2)
    Box(X,Y,W,H)
  Else
    DrawingMode(#PB_2DDrawing_Default)
    Box(X,Y,W,H,SBColor)
  EndIf
  
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(X,Y,W,H, *mg\Color_Line)
  
  Select SType
      
    Case #MyGrid_CellType_Normal
      
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W,H, SAlign, *mg\WrapText)
      
    Case #MyGrid_CellType_Checkbox
      checked = Val(wrd)
      DrawingMode(#PB_2DDrawing_Default)
      DrawCheckBox(X,Y,W,H, #MyGrid_CheckBox_Width, checked, #MyGrid_CheckBox_Color)
      
    Case #MyGrid_CellType_Button
      ;DrawButton(X+2,Y+2,W-4,H-4,SBColor)
      DrawButton(X+1,Y+1,W-2,H-2,SBColor)
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W,H, SAlign, *mg\WrapText)
      
    Case #MyGrid_CellType_Combo
      DrawingMode(#PB_2DDrawing_Transparent)
      If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
      FrontColor(SFColor)
      MyDrawText(wrd, X,Y,W-16,H, SAlign, *mg\WrapText)
      
      DrawingMode(#PB_2DDrawing_Default)
      DrawCombo(X,Y,W,H)
      
  EndSelect
  
EndProcedure
Procedure.i _MyGrid_DrawCell(*mg._MyGrid_Type, Row, Col)
  Protected Multi = _MyGrid_MultiOfCell(*mg, Row, Col)
  
  If Multi >= 0
    __MyGrid_DrawMultiCell(*mg, Multi)
  Else
    __MyGrid_DrawSingleCell(*mg, Row, Col)
  EndIf
  
EndProcedure

Procedure.i _MyGrid_DrawFocus(*mg._MyGrid_Type)
  ; draws rectangle focus in current cell
  Protected x,y,w,h,ar,ac, c, mlt
  Protected bc._MyGrid_Rectangle_Type
  
  
  If *mg\Color_FocusBorder < 0 : ProcedureReturn : EndIf
  If _MyGrid_HasBlock(*mg)
    DrawingMode(#PB_2DDrawing_Outlined)
    x = *mg\BlockX
    w = *mg\BlockW
    y = *mg\BlockY
    h = *mg\BlockH
    c = *mg\Color_FocusBorder
    Box(x, y, w, h, c)
    Box(x+1, y+1, w-2, h-2, c)
    
  Else
    
    mlt = _MyGrid_MultiOfCell(*mg, *mg\Row, *mg\Col)
    If mlt < 0
      ar = _MyGrid_Area_Of_Row(*mg, *mg\Row)
      ac = _MyGrid_Area_Of_Col(*mg, *mg\Col)
      If ar >= 0 And ac >= 0
        
        SelectElement(*mg\LstAreaCol(), ac)
        SelectElement(*mg\LstAreaRow(), ar)
        DrawingMode(#PB_2DDrawing_Outlined)
        x = *mg\LstAreaCol()\X
        w = *mg\LstAreaCol()\Width
        y = *mg\LstAreaRow()\Y
        h = *mg\LstAreaRow()\Height
        c = *mg\Color_FocusBorder
        Box(x, y, w, h, c)
        Box(x+1, y+1, w-2, h-2, c)
      EndIf
      
    Else
      SelectElement( *mg\LstMulti() , mlt)
      If _MyGrid_RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
        DrawingMode(#PB_2DDrawing_Outlined)
        x = bc\X
        w = bc\W
        y = bc\Y
        h = bc\H
        c = *mg\Color_FocusBorder
        Box(x, y, w, h, c)
        Box(x+1, y+1, w-2, h-2, c)
      EndIf
      
    EndIf
  EndIf
  
EndProcedure
Procedure.i _MyGrid_MoveFocus(*mg._MyGrid_Type, Row, Col)
  If StartDrawing(CanvasOutput(*mg\Gadget)) 
    _MyGrid_DrawCell(*mg, *mg\Row, *mg\Col)
    *mg\Row = Row
    *mg\Col = Col
    _MyGrid_DrawFocus(*mg)
    StopDrawing()
  EndIf
  
EndProcedure

Procedure.i _MyGrid_DrawCurrentCell(*mg._MyGrid_Type)
  If StartDrawing(CanvasOutput(*mg\Gadget)) 
    _MyGrid_DrawCell(*mg, *mg\Row, *mg\Col)
    _MyGrid_DrawFocus(*mg)
    StopDrawing()
  EndIf
EndProcedure

Procedure   _MyGrid_Draw(*mg._MyGrid_Type)
  Protected WW,HH,x,y,w,h,Row,Col,clr,area, ar, ac, t
  Protected mlt, Dim tMltDone.i(0)
  
  If *mg\NoRedraw = #True : ProcedureReturn : EndIf
  t = ElapsedMilliseconds()
  
  WW = *mg\GadgetW
  HH = *mg\GadgetH
  
  ; buildign screen areas before drawing
  _MyGrid_BuildAreas(*mg)
  
  If Not StartDrawing(CanvasOutput(*mg\Gadget)) : ProcedureReturn : EndIf
  ResetGradientColors()
  
  ; 1. --- Drawing Backgrounds and Texts
  x = 0 : w = WW : y = 0 : h = HH 
  FirstElement(*mg\LstStyle())
  clr = *mg\LstStyle()\BackColor
  Box(x,y,w,h,clr)
  
  If ListSize(*mg\LstMulti()) = 0
    ;         ForEach *mg\LstAreaRow()
    ;             Row = *mg\LstAreaRow()\Row
    ;             y   = *mg\LstAreaRow()\Y
    ;             h   = *mg\LstAreaRow()\Height
    ;             
    ;             ForEach *mg\LstAreaCol()
    ;                 Col = *mg\LstAreaCol()\Col
    ;                 x   = *mg\LstAreaCol()\X
    ;                 w   = *mg\LstAreaCol()\Width
    ;                 _MyGrid_BasicDrawCell(*mg, Row, Col, x,y,w,h)
    ;             Next
    ;         Next
    ForEach *mg\LstAreaRow()
      Row = *mg\LstAreaRow()\Row
      ForEach *mg\LstAreaCol()
        Col = *mg\LstAreaCol()\Col
        __MyGrid_DrawSingleCell(*mg, Row, Col)
      Next
    Next
  Else
    Dim tMltDone( ListSize( *mg\LstMulti()) )
    ForEach *mg\LstAreaRow()
      Row = *mg\LstAreaRow()\Row
      ForEach *mg\LstAreaCol()
        Col = *mg\LstAreaCol()\Col
        mlt = _MyGrid_MultiOfCell(*mg, Row, Col)
        If mlt >= 0
          If tMltDone(mlt) = 0
            __MyGrid_DrawMultiCell(*mg, mlt)
            tMltDone(mlt) = 1
          EndIf
        Else
          __MyGrid_DrawSingleCell(*mg, Row, Col)
        EndIf
      Next
    Next
  EndIf
  
  ; drawing merged cells if any
  ;If ListSize(*mg\LstMulti()) > 0
  ;    _MyGrid_DrawMultiCells(*mg)
  ;EndIf
  
  ; drawing block if any
  If _MyGrid_HasBlock(*mg)
    _MyGrid_BlockSize(*mg)
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(*mg\BlockX, *mg\BlockY, *mg\BlockW, *mg\BlockH,*mg\Color_BlockBack)
  EndIf
  
  ; grey-area back color
  DrawingMode(#PB_2DDrawing_Default)
  clr = *mg\Color_Background
  LastElement(*mg\LstAreaCol())
  LastElement(*mg\LstAreaRow())
  
  x = *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width
  Box(x,0, WW - x,HH,clr)
  y = *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height
  Box(0,y,WW,HH - y,clr)
  
  _MyGrid_DrawFocus(*mg)
  
  StopDrawing()
  
  _MyGrid_GridToScrolls(*mg)
  
  Debug " DRAW .... : " + Str(ElapsedMilliseconds() - t) ;+  " ... " + _MyGrid_DebugBlock(*mg)
  
EndProcedure

;-------------------------------------------------------------------------------------------- 
;--- Navigation & Scrolling
;-------------------------------------------------------------------------------------------- 
Procedure.i _MyGrid_NearestTopRow(*mg._MyGrid_Type, Row)
  ; return the TopRow that requires least moves so Row is visible
  Protected i, h, ret
  
  If FindMapElement( *mg\DicAreaOfRow() , Str(Row))
    SelectElement(*mg\LstAreaRow() , *mg\DicAreaOfRow())
    If *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height <= *mg\GadgetH
      ProcedureReturn *mg\TopRow
    Else
      If *mg\TopRow < *mg\LastTopRow
        ProcedureReturn *mg\TopRow + 1
      Else
        ProcedureReturn *mg\TopRow
      EndIf
    EndIf
  EndIf
  
  If Row <= *mg\TopRow
    If Row < *mg\FrstTopRow : ProcedureReturn *mg\FrstTopRow : EndIf
    ProcedureReturn Row
  EndIf
  
  For i = 0 To *mg\FrozenRow
    h = h + (*mg\RowHeight(i) - 1)
  Next
  h = h + (*mg\RowHeight(Row) - 1)
  
  ret = Row
  For i = Row-1 To 1 Step -1
    If h + *mg\RowHeight(i) > *mg\GadgetH : Break : EndIf
    h = h + (*mg\RowHeight(i) - 1)
    ret = i
  Next i
  ProcedureReturn ret
  
EndProcedure
Procedure.i _MyGrid_NearestTopCol(*mg._MyGrid_Type, Col)
  ; return the TopCol that requires least moves so Col is visible
  Protected i, w, ret
  
  If FindMapElement( *mg\DicAreaOfCol() , Str(Col))
    SelectElement(*mg\LstAreaCol() , *mg\DicAreaOfCol())
    If *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width <= *mg\GadgetW
      ProcedureReturn *mg\TopCol
    Else
      If *mg\TopCol < *mg\LastTopCol
        ProcedureReturn *mg\TopCol + 1
      Else
        ProcedureReturn *mg\TopCol
      EndIf
    EndIf
  EndIf
  
  If Col <= *mg\TopCol
    If Col < *mg\FrstTopCol : ProcedureReturn *mg\FrstTopCol : EndIf
    ProcedureReturn Col
  EndIf
  
  For i = 0 To *mg\FrozenCol
    w = w + (*mg\ColWidth(i) - 1)
  Next
  w = w + (*mg\ColWidth(Col) - 1)
  
  ret = Col
  For i = Col-1 To 1 Step -1
    If w + *mg\ColWidth(i) > *mg\GadgetW : Break : EndIf
    w = w + (*mg\ColWidth(i) - 1)
    ret = i
  Next i
  ProcedureReturn ret
  
EndProcedure

Procedure.i _MyGrid_PriorCol(*mg._MyGrid_Type, Row, Col, MultiAsOneCell)
  ; return the previous col (left) having width > 0 OR -1
  Protected ret, multi, base = Col-1
  
  If MultiAsOneCell
    multi = _MyGrid_MultiOfCell(*mg, Row, Col)
    If multi >= 0
      SelectElement(*mg\LstMulti() , multi)
      base = *mg\LstMulti()\C1 - 1
    EndIf
  EndIf
  
  For ret = base To 1 Step  -1
    If *mg\ColWidth(ret) > 0  : ProcedureReturn ret : EndIf
  Next
  ProcedureReturn -1
  
EndProcedure
Procedure.i _MyGrid_NextCol( *mg._MyGrid_Type, Row, Col, MultiAsOneCell)
  ; return the next col (right) having width > 0 OR -1
  Protected ret, multi, base = Col+1
  
  If MultiAsOneCell
    multi = _MyGrid_MultiOfCell(*mg, Row, Col)
    If multi >= 0
      SelectElement(*mg\LstMulti() , multi)
      base = *mg\LstMulti()\C2 + 1
    EndIf
  EndIf
  
  For ret = base To *mg\Cols
    If *mg\ColWidth(ret) > 0  : ProcedureReturn ret : EndIf
  Next
  ProcedureReturn -1
  
EndProcedure
Procedure.i _MyGrid_AboveRow(*mg._MyGrid_Type, Row, Col, MultiAsOneCell)
  ; return the above row (up) having height > 0 OR -1
  Protected ret, multi, base = Row-1
  
  If MultiAsOneCell
    multi = _MyGrid_MultiOfCell(*mg, Row, Col)
    If multi >= 0
      SelectElement(*mg\LstMulti() , multi)
      base = *mg\LstMulti()\R1 - 1
    EndIf
  EndIf
  
  For ret = base To 1 Step  -1
    If *mg\RowHeight(ret) > 0  : ProcedureReturn ret : EndIf
  Next
  ProcedureReturn -1
  
EndProcedure
Procedure.i _MyGrid_BelowRow(*mg._MyGrid_Type, Row, Col, MultiAsOneCell)
  ; return the below row (down) having height > 0 OR -1
  Protected ret, multi, base = Row+1
  
  If MultiAsOneCell
    multi = _MyGrid_MultiOfCell(*mg, Row, Col)
    If multi >= 0
      SelectElement(*mg\LstMulti() , multi)
      base = *mg\LstMulti()\R2 + 1
    EndIf
  EndIf
  
  For ret = base To *mg\Rows
    If *mg\RowHeight(ret) > 0  : ProcedureReturn ret : EndIf
  Next
  ProcedureReturn -1
  
EndProcedure

; return true if we need to redraw
Procedure.i _MyGrid_MoveUp(*mg._MyGrid_Type, xStep = 1, moveWhat = #MyGrid_Move_Focus)
  Protected i, stp, lmt, Row, Col
  
  If (moveWhat = #MyGrid_Move_Block) And (_MyGrid_HasBlock(*mg) = #False) : _MyGrid_StartBlock(*mg) : EndIf
  
  Select moveWhat
    Case #MyGrid_Move_Focus: Row = *mg\Row      : lmt = *mg\FrstVisRow
    Case #MyGrid_Move_TopRC: Row = *mg\TopRow   : lmt = *mg\FrstTopRow
    Case #MyGrid_Move_Block: Row = *mg\Row2     : lmt = *mg\FrstVisRow
  EndSelect
  
  If (xStep <= 0 ) Or (Row <= lmt) : ProcedureReturn #False : EndIf
  
  Col = *mg\Col
  Repeat
    i = _MyGrid_AboveRow(*mg, Row, Col, Bool(moveWhat = #MyGrid_Move_Focus))
    If i <= 0 : Break : EndIf
    Row = i
    stp = stp + 1 : If stp >= xStep : Break : EndIf
  ForEver
  
  Select moveWhat
    Case #MyGrid_Move_Focus
      If Row = *mg\Row : ProcedureReturn #False : EndIf
      i = _MyGrid_NearestTopRow(*mg, Row)
      If *mg\TopRow <> i
        *mg\TopRow = i
        *mg\Row = Row
        ProcedureReturn #True
      Else
        _MyGrid_MoveFocus(*mg, Row, Col)
      EndIf
      
    Case #MyGrid_Move_TopRC
      If Row = *mg\TopRow : ProcedureReturn #False : EndIf
      *mg\TopRow = Row
      ProcedureReturn #True
      
    Case #MyGrid_Move_Block
      If Row = *mg\Row2 : ProcedureReturn #False : EndIf
      *mg\Row2 = Row
      *mg\TopRow = _MyGrid_NearestTopRow(*mg, *mg\Row2)
      ProcedureReturn #True
      
  EndSelect
  
EndProcedure
Procedure.i _MyGrid_MoveDown(*mg._MyGrid_Type, xStep = 1, moveWhat = #MyGrid_Move_Focus)
  Protected i, stp, lmt, Row, Col
  
  If (moveWhat = #MyGrid_Move_Block) And (_MyGrid_HasBlock(*mg) = #False) : _MyGrid_StartBlock(*mg) : EndIf
  
  Select moveWhat
    Case #MyGrid_Move_Focus: Row = *mg\Row      : lmt = *mg\LastVisRow
    Case #MyGrid_Move_TopRC: Row = *mg\TopRow   : lmt = *mg\LastTopRow
    Case #MyGrid_Move_Block: Row = *mg\Row2     : lmt = *mg\LastVisRow
  EndSelect
  
  If (xStep <= 0 ) Or (Row >= lmt) : ProcedureReturn #False : EndIf
  
  Col = *mg\Col
  Repeat
    i = _MyGrid_BelowRow(*mg, Row, Col, Bool(moveWhat = #MyGrid_Move_Focus))
    If i <= 0 : Break : EndIf
    Row = i
    stp = stp + 1 : If stp >= xStep : Break : EndIf
  ForEver
  
  Select moveWhat
    Case #MyGrid_Move_Focus
      If Row = *mg\Row : ProcedureReturn #False : EndIf
      i = _MyGrid_NearestTopRow(*mg, Row)
      If *mg\TopRow <> i
        *mg\TopRow = i
        *mg\Row = Row
        ProcedureReturn #True
      Else
        _MyGrid_MoveFocus(*mg, Row, Col)
      EndIf
      
    Case #MyGrid_Move_TopRC
      If Row = *mg\TopRow : ProcedureReturn #False : EndIf
      *mg\TopRow = Row
      ProcedureReturn #True
      
    Case #MyGrid_Move_Block
      If Row = *mg\Row2 : ProcedureReturn #False : EndIf
      *mg\Row2    = Row
      *mg\TopRow  = _MyGrid_NearestTopRow(*mg, *mg\Row2)
      ProcedureReturn #True
      
  EndSelect
  
EndProcedure
Procedure.i _MyGrid_MoveLeft(*mg._MyGrid_Type, xStep = 1, moveWhat = #MyGrid_Move_Focus)
  Protected i, stp, lmt, Row, Col
  
  If (moveWhat = #MyGrid_Move_Block) And (_MyGrid_HasBlock(*mg) = #False) : _MyGrid_StartBlock(*mg) : EndIf
  
  Select moveWhat
    Case #MyGrid_Move_Focus: Col = *mg\Col      : lmt = *mg\FrstVisCol
    Case #MyGrid_Move_TopRC: Col = *mg\TopCol   : lmt = *mg\FrstTopCol
    Case #MyGrid_Move_Block: Col = *mg\Col2     : lmt = *mg\FrstVisCol
  EndSelect
  
  If (xStep <= 0 ) Or (Col <= lmt) : ProcedureReturn #False : EndIf
  
  Row = *mg\Row
  Repeat
    i = _MyGrid_PriorCol(*mg, Row, Col, Bool(moveWhat = #MyGrid_Move_Focus))
    If i <= 0 : Break : EndIf
    Col = i
    stp = stp + 1 : If stp >= xStep : Break : EndIf
  ForEver
  
  Select moveWhat
    Case #MyGrid_Move_Focus
      If Col = *mg\Col : ProcedureReturn #False : EndIf
      i = _MyGrid_NearestTopCol(*mg, Col)
      If *mg\TopCol <> i
        *mg\TopCol = i
        *mg\Col = Col
        ProcedureReturn #True
      Else
        _MyGrid_MoveFocus(*mg, Row, Col)
      EndIf
      
    Case #MyGrid_Move_TopRC
      If Col = *mg\TopCol : ProcedureReturn #False : EndIf
      *mg\TopCol = Col
      ProcedureReturn #True
      
    Case #MyGrid_Move_Block
      If Col = *mg\Col2 : ProcedureReturn #False : EndIf
      *mg\Col2    = Col
      ;*mg\TopRow  = _MyGrid_NearestTopRow(*mg, *mg\Row2)
      *mg\TopCol  = _MyGrid_NearestTopCol(*mg, *mg\Col2)
      ProcedureReturn #True
      
  EndSelect
  
EndProcedure
Procedure.i _MyGrid_MoveRight(*mg._MyGrid_Type, xStep = 1, moveWhat = #MyGrid_Move_Focus)
  Protected i, stp, lmt, Row, Col
  
  If (moveWhat = #MyGrid_Move_Block) And (_MyGrid_HasBlock(*mg) = #False) : _MyGrid_StartBlock(*mg) : EndIf
  
  Select moveWhat
    Case #MyGrid_Move_Focus: Col = *mg\Col      : lmt = *mg\LastVisCol
    Case #MyGrid_Move_TopRC: Col = *mg\TopCol   : lmt = *mg\LastTopCol
    Case #MyGrid_Move_Block: Col = *mg\Col2     : lmt = *mg\LastVisCol
  EndSelect
  
  If (xStep <= 0 ) Or (Col >= lmt) : ProcedureReturn #False : EndIf
  
  Row = *mg\Row
  Repeat
    i = _MyGrid_NextCol(*mg, Row, Col, Bool(moveWhat = #MyGrid_Move_Focus))
    If i <= 0 : Break : EndIf
    Col = i
    stp = stp + 1 : If stp >= xStep : Break : EndIf
  ForEver
  
  Select moveWhat
    Case #MyGrid_Move_Focus
      If Col = *mg\Col : ProcedureReturn #False : EndIf
      i = _MyGrid_NearestTopCol(*mg, Col)
      If *mg\TopCol <> i
        *mg\TopCol = i
        *mg\Col = Col
        ProcedureReturn #True
      Else
        _MyGrid_MoveFocus(*mg, Row, Col)
      EndIf
      
    Case #MyGrid_Move_TopRC
      If Col = *mg\TopCol : ProcedureReturn #False : EndIf
      *mg\TopCol = Col
      ProcedureReturn #True
      
    Case #MyGrid_Move_Block
      If Col = *mg\Col2 : ProcedureReturn #False : EndIf
      *mg\Col2    = Col
      ;*mg\TopRow  = _MyGrid_NearestTopRow(*mg, *mg\Row2)
      *mg\TopCol  = _MyGrid_NearestTopCol(*mg, *mg\Col2)
      ProcedureReturn #True
      
  EndSelect
  
EndProcedure
Procedure.i _MyGrid_ExtendBlock_XY(*mg._MyGrid_Type, X,Y)
  ; extends current block via pressed mouse-move ; x,y are coord within canvas
  Protected Row,Col, dskX, dskY, xStep, ret1, ret2, outside, mgnX, mgnY
  
  mgnX = 40
  mgnY = 30
  ;If (Y < 0) Or (Y > *mg\Height) Or (X < 0) Or (X > *mg\Width) ; outside
  
  If Y < 0 
    xStep = 1 : If Y < mgnY : xStep = 10 : EndIf
    _MyGrid_MoveUp(*mg, xStep, #MyGrid_Move_Block)
  EndIf
  If Y > *mg\GadgetH
    xStep = 1 : If (Y - *mg\GadgetH) > mgnY : xStep = 10 : EndIf
    _MyGrid_MoveDown( *mg, 10, #MyGrid_Move_Block)
  EndIf
  If X < 0
    xStep = 1 : If X < mgnX : xStep = 10 : EndIf
    _MyGrid_MoveLeft( *mg, 10, #MyGrid_Move_Block)
  EndIf
  If X > *mg\GadgetW
    xStep = 1 : If (X - *mg\GadgetW) > mgnX : xStep = 10 : EndIf
    _MyGrid_MoveRight(*mg, 10, #MyGrid_Move_Block)
  EndIf
  
  Row = _MyGrid_Row_Of_Y(*mg, Y)
  Col = _MyGrid_Col_Of_X(*mg, X)
  
  If (Row = *mg\Row2) And (Col = *mg\Col2) : ProcedureReturn #False : EndIf
  
  If (Col > 0) And (*mg\Col2 <> Col)
    xStep = Abs(*mg\Col2 - Col)
    If Col > *mg\Col2: _MyGrid_MoveRight(*mg, xStep, #MyGrid_Move_Block) : EndIf
    If Col < *mg\Col2: _MyGrid_MoveLeft(*mg, xStep, #MyGrid_Move_Block) : EndIf
    *mg\Col2 = Col
  EndIf
  
  If (Row > 0) And (*mg\Row2 <> Row)
    xStep = Abs(*mg\Row2 - Row)
    If Row > *mg\Row2: _MyGrid_MoveDown(*mg, xStep, #MyGrid_Move_Block) : EndIf
    If Row < *mg\Row2: _MyGrid_MoveUp(*mg, xStep, #MyGrid_Move_Block) : EndIf
    *mg\Row2 = Row
  EndIf
  ProcedureReturn #True
  
EndProcedure

Procedure.i _MyGrid_AdjustScrolls(*mg._MyGrid_Type)
  ; Scrolls settings, ideally we have: [FirstTop = minState] And [LastTop = maxState] and [StateFactor = 1]
  ; if we cant then we use proprtional: FirstTop # minState and LastTop # maxState
  ; Needs be called after any change in the number of visible Cols/Rows
  Protected i, scrPage
  
  _MyGrid_RefreshCounters(*mg)
  If IsGadget(*mg\ColScroll)
    If *mg\LastTopCol <= #MyGrid_Scroll_Max
      ; LastTop = scrMax - scrPage + 1  ==>  scrMax = LastTop + scrPage - 1
      ; we have full match:  CurTop = 1 * CurState
      scrPage = #MyGrid_Scroll_PageSize
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Minimum, *mg\FrstTopCol)
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_PageLength, scrPage)
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Maximum, *mg\LastTopCol + scrPage - 1)
      *mg\StateFactorCol = 1
      *mg\ColScrollMin   = *mg\FrstTopCol
      *mg\ColScrollMax   = *mg\LastTopCol
    Else
      ; we have packet match:  CurTop = Factor * CurState
      scrPage = #MyGrid_Scroll_PageSize
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Minimum, *mg\FrstTopCol)
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_PageLength, scrPage)
      SetGadgetAttribute(*mg\ColScroll, #PB_ScrollBar_Maximum, #MyGrid_Scroll_Max + scrPage - 1)
      *mg\StateFactorCol = (*mg\LastTopCol - *mg\FrstTopCol) / (#MyGrid_Scroll_Max - *mg\FrstTopCol)
      *mg\ColScrollMin   = *mg\FrstTopCol
      *mg\ColScrollMax   = #MyGrid_Scroll_Max
    EndIf
  EndIf
  
  If IsGadget(*mg\RowScroll)
    If *mg\LastTopRow <= #MyGrid_Scroll_Max
      ; LastTop = scrMax - scrPage + 1  ==>  scrMax = LastTop + scrPage - 1
      ; we have full match:  CurTop = 1 * CurState
      scrPage = #MyGrid_Scroll_PageSize
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum, *mg\FrstTopRow)
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_PageLength, scrPage)
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum, *mg\LastTopRow + scrPage - 1)
      *mg\StateFactorRow = 1
      *mg\RowScrollMin   = *mg\FrstTopRow
      *mg\RowScrollMax   = *mg\LastTopRow
    Else
      ; we have packet match:  CurTop = Factor * CurState
      scrPage = #MyGrid_Scroll_PageSize
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum, *mg\FrstTopRow)
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_PageLength, scrPage)
      SetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum, #MyGrid_Scroll_Max + scrPage - 1)
      *mg\StateFactorRow = (*mg\LastTopRow - *mg\FrstTopRow) / (#MyGrid_Scroll_Max - *mg\FrstTopRow)
      *mg\RowScrollMin   = *mg\FrstTopRow
      *mg\RowScrollMax   = #MyGrid_Scroll_Max
    EndIf
  EndIf
  ;Debug " StateFactorRow = " + StrF(*mg\StateFactorRow)
EndProcedure
Procedure.i _MyGrid_GridToScrolls(*mg._MyGrid_Type)
  ; updates Scrolls are per Grid fields: TopCol / TopRow
  Protected curState, curTop
  
  If IsGadget(*mg\ColScroll)
    curTop = *mg\TopCol
    
    If *mg\FrstTopCol = *mg\LastTopCol Or curTop = *mg\FrstTopCol
      curState = *mg\ColScrollMin
      
    ElseIf curTop = *mg\LastTopCol
      curState = *mg\ColScrollMax
      
    Else
      If *mg\StateFactorCol : curState = Int(curTop / *mg\StateFactorCol) : EndIf
    EndIf
    SetGadgetState(*mg\ColScroll , curState)
  EndIf
  
  If IsGadget(*mg\RowScroll)
    curTop = *mg\TopRow
    
    If *mg\FrstTopRow = *mg\LastTopRow Or curTop = *mg\FrstTopRow
      curState = *mg\RowScrollMin
      
    ElseIf curTop = *mg\LastTopRow
      curState = *mg\RowScrollMax
      
    Else
      If *mg\StateFactorRow : curState = Int(curTop / *mg\StateFactorRow) : EndIf
    EndIf
    SetGadgetState(*mg\RowScroll , curState)
  EndIf
  
EndProcedure
Procedure.i _MyGrid_ScrollsToGrid(*mg._MyGrid_Type, AdjustCol.i)
  ; read scrolls states and update grid fields: TopCol/TopRow
  Protected curState, curTop, redraw
  
  If IsGadget(*mg\ColScroll) And AdjustCol
    curState = GetGadgetState(*mg\ColScroll)
    
    If curState = *mg\ColScrollMin Or *mg\ColScrollMax = *mg\ColScrollMin
      curTop = *mg\FrstTopCol
    ElseIf curState = *mg\ColScrollMax
      curTop = *mg\LastTopCol
    Else
      curTop = *mg\StateFactorCol * curState
    EndIf
    
    If     curTop < *mg\TopCol  ; moving right
      Repeat
        If *mg\ColWidth(curTop) > 0  : Break : EndIf
        If curTop <= *mg\FrstTopCol : Break : EndIf
        curTop = curTop - 1
      ForEver
    ElseIf curTop > *mg\TopCol  ; moving left
      Repeat
        If *mg\ColWidth(curTop) > 0 : Break : EndIf
        If curTop >= *mg\LastTopCol : Break : EndIf
        curTop = curTop + 1
      ForEver
    EndIf
    
    If *mg\TopCol <> curTop
      *mg\TopCol = curTop
      redraw = #True
    EndIf
  EndIf
  
  If IsGadget(*mg\RowScroll)  And AdjustCol = 0
    curState = GetGadgetState(*mg\RowScroll)
    
    If curState = *mg\RowScrollMin Or *mg\RowScrollMax = *mg\RowScrollMin
      curTop = *mg\FrstTopRow
    ElseIf curState = *mg\RowScrollMax
      curTop = *mg\LastTopRow
    Else
      curTop = *mg\StateFactorRow * curState
    EndIf
    
    If     curTop < *mg\TopRow  ; moving up
      Repeat
        If *mg\RowHeight(curTop) > 0  : Break : EndIf
        If curTop <= *mg\FrstTopRow : Break : EndIf
        curTop = curTop - 1
      ForEver
    ElseIf curTop > *mg\TopRow  ; moving down
      Repeat
        If *mg\RowHeight(curTop) > 0 : Break : EndIf
        If curTop >= *mg\LastTopRow : Break : EndIf
        curTop = curTop + 1
      ForEver
    EndIf
    
    If *mg\TopRow <> curTop
      *mg\TopRow = curTop
      redraw = #True
    EndIf
    Debug GetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Minimum)
    Debug GetGadgetAttribute(*mg\RowScroll, #PB_ScrollBar_Maximum)
    Debug *mg\TopRow
  EndIf
  
  ProcedureReturn redraw
  
EndProcedure
Procedure.i _MyGrid_SynchronizeGridCols()
  ; internal event handler: update cols as per ColScroll ... requested by end-user
  Protected *mg._MyGrid_Type = GetGadgetData(EventGadget())
  
  If _MyGrid_ScrollsToGrid(*mg, #True)
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure
Procedure.i _MyGrid_SynchronizeGridRows()
  ; internal event handler: update rows as per RowScroll ... requested by end-user
  Protected *mg._MyGrid_Type = GetGadgetData(EventGadget())
  
  If _MyGrid_ScrollsToGrid(*mg, #False)
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure

;-------------------------------------------------------------------------------------------- 
;--- Editing
;-------------------------------------------------------------------------------------------- 
Procedure.i _MyGrid_ManageEdit(*mg._MyGrid_Type, ky.s, EnterPressed, SimpleClick)
  Protected winNbr, gdt, evnt, evMn, evGt, evTy, gEvt, exitEdit.i = #False, nr=-1,nc=-1
  Protected multi,ar,ac,r,c,x,y,w,h,editMode, txtEdit, lstEdit, oTxt.s, nTxt.s, wrd.s
  Protected SBColor, SFColor, SAlign, SFont
  Protected bc._MyGrid_Rectangle_Type
  
  multi = _MyGrid_MultiOfCell(*mg, *mg\Row, *mg\Col)
  If multi >= 0
    ;ProcedureReturn #False ; for now we do not edit spanned-cells until we can draw each properly
    SelectElement(*mg\LstMulti() , multi)
    r = *mg\LstMulti()\R1 : c = *mg\LstMulti()\C1
  Else
    r = *mg\Row : c = *mg\Col
  EndIf
  __MyGrid_SelectStyle(*mg, r, c)
  
  If *mg\LstStyle()\Editable = #False : ProcedureReturn #False : EndIf
  editMode = *mg\LstStyle()\EditMode
  
  ar = _MyGrid_Area_Of_Row(*mg, r)
  ac = _MyGrid_Area_Of_Col(*mg, c)
  If ar < 0 Or ac < 0 : ProcedureReturn #False : EndIf
  
  If multi >= 0
    SelectElement( *mg\LstMulti() , multi)
    If _MyGrid_RectCoord(*mg, *mg\LstMulti()\R1, *mg\LstMulti()\C1, *mg\LstMulti()\R2, *mg\LstMulti()\C2, @bc)
      x = bc\X + GadgetX(*mg\Gadget)
      w = bc\W
      y = bc\Y + GadgetY(*mg\Gadget)
      h = bc\H
    EndIf
  Else
    SelectElement(*mg\LstAreaCol(), ac)
    SelectElement(*mg\LstAreaRow(), ar)
    x = *mg\LstAreaCol()\X + GadgetX(*mg\Gadget)
    w = *mg\LstAreaCol()\Width
    y = *mg\LstAreaRow()\Y + GadgetY(*mg\Gadget)
    h = *mg\LstAreaRow()\Height
  EndIf
  
  oTxt = _MyGrid_GetCellText(*mg, r, c)       ; original cell text
  nTxt = oTxt
  
  winNbr = *mg\Window
  
  Select *mg\LstStyle()\CellType
      
    Case #MyGrid_CellType_Checkbox
      ; an Enter or Space in a Checkbox are equivalent to Button-Click (check/uncheck)
      If ky = " "  Or EnterPressed Or SimpleClick 
        If  Val(oTxt) = 0
          _MyGrid_SetCellTextEvent(*mg, r, c, "1")
        Else
          _MyGrid_SetCellTextEvent(*mg, r, c, "0")
        EndIf
        _MyGrid_DrawCurrentCell(*mg)
      EndIf
      ProcedureReturn #False
      
    Case #MyGrid_CellType_Button
      If ky = " "  Or EnterPressed Or SimpleClick 
        *mg\ClickedRow = r : *mg\ClickedCol = c
        PostEvent(#MyGrid_Event_Click, *mg\Window, *mg\Gadget) ; throw an event in the loop
      EndIf
      ProcedureReturn #False
      
    Case #MyGrid_CellType_Combo
      If SimpleClick Or EnterPressed : wrd = oTxt : EndIf
      lstEdit = #True
      
    Case #MyGrid_CellType_Normal
      If SimpleClick : ProcedureReturn #False : EndIf ; getting focus is not entring edit mode!
      Select editMode
        Case #MyGrid_Edit_Over
          wrd = ky
        Case #MyGrid_Edit_Append
          wrd = oTxt + ky
      EndSelect
      If EnterPressed : wrd = oTxt : EndIf
      txtEdit = #True
      
    Default
      ProcedureReturn #False
      
  EndSelect
  
  AddKeyboardShortcut(winNbr, #PB_Shortcut_Escape     , #_MyGrid_ExitEdit)
  AddKeyboardShortcut(winNbr, #PB_Shortcut_Tab        , #_MyGrid_ExitEdit_Vld_Rt)
  AddKeyboardShortcut(winNbr, #PB_Shortcut_Return     , #_MyGrid_ExitEdit_Vld_Rt)
  
  If editMode = #MyGrid_Edit_Over     ; navigation-keys ---> exit editing
    AddKeyboardShortcut(winNbr, #PB_Shortcut_Tab        , #_MyGrid_ExitEdit_Vld_Rt)
    AddKeyboardShortcut(winNbr, #PB_Shortcut_Return     , #_MyGrid_ExitEdit_Vld_Rt)
    AddKeyboardShortcut(winNbr, #PB_Shortcut_Right      , #_MyGrid_ExitEdit_Vld_Rt)
    AddKeyboardShortcut(winNbr, #PB_Shortcut_Left       , #_MyGrid_ExitEdit_Vld_Lt)
    If txtEdit
      AddKeyboardShortcut(winNbr, #PB_Shortcut_Up     , #_MyGrid_ExitEdit_Vld_Up)
      AddKeyboardShortcut(winNbr, #PB_Shortcut_Down   , #_MyGrid_ExitEdit_Vld_Dn)
      AddKeyboardShortcut(winNbr, #PB_Shortcut_PageUp , #_MyGrid_ExitEdit_Vld_PUp)
      AddKeyboardShortcut(winNbr, #PB_Shortcut_PageDown, #_MyGrid_ExitEdit_Vld_PDn)
    EndIf
  EndIf
  
  If txtEdit
    gdt = *mg\TxtEdit
    ResizeGadget(gdt, x+2, y+2, w-4, h-4)
    CompilerSelect #PB_Compiler_OS  ; pushing carat to the end
      CompilerCase #PB_OS_Windows
        Delay(1): keybd_event_(#VK_END, 0, 0, 0)
      CompilerCase #PB_OS_Linux
      CompilerCase #PB_OS_MacOS
      CompilerDefault                           
    CompilerEndSelect
  EndIf
  
  If lstEdit
    gdt = *mg\CmbEdit
    _MyGrid_LoadInEditCombo(*mg, ListIndex(*mg\LstStyle()))
    ResizeGadget(gdt, x, y+h, w, #MyGrid_Combo_Height)
  EndIf
  SetGadgetText(gdt, wrd)
  HideGadget(gdt, 0)
  
  SBColor = *mg\LstStyle()\BackColor
  SFColor = *mg\LstStyle()\ForeColor
  SAlign  = *mg\LstStyle()\Aling
  SFont   = *mg\LstStyle()\Font
  
  If IsFont(SFont) : SetGadgetFont(gdt, FontID(SFont)) : EndIf
  SetGadgetColor(gdt, #PB_Gadget_FrontColor, SFColor)
  SetGadgetColor(gdt, #PB_Gadget_BackColor , *mg\Color_FocusBack)
  
  DisableGadget(*mg\Gadget, 1)
  SetActiveGadget(gdt)
  
  Repeat
    evnt = WaitWindowEvent()
    evMn = EventMenu()
    evGt = EventGadget()
    evTy = EventType()
    gEvt = 0
    Select evnt
      Case  #PB_Event_Menu
        If evMn >= #_MyGrid_ExitEdit And evMn <= #_MyGrid_ExitEdit_Vld_PDn
          gEvt = evMn
          exitEdit = #True
        EndIf
        
      Case #PB_Event_LeftClick, #PB_Event_RightClick, #PB_Event_CloseWindow
        x = WindowMouseX(winNbr) - *mg\DeltaX   ; screen coord. relativised to grid
        y = WindowMouseY(winNbr) - *mg\DeltaY
        If x >= 0 And x <= *mg\GadgetW And y >= 0 And y <= *mg\GadgetH
          nc = _MyGrid_Col_Of_X(*mg, x)
          nr = _MyGrid_Row_Of_Y(*mg, y)
          gEvt = #_MyGrid_ExitEdit_Vld
        Else
          gEvt = #_MyGrid_ExitEdit_Out
        EndIf
        exitEdit = #True
        
        
      Case #PB_Event_Gadget
        If evGt = gdt
          If lstEdit And evTy = #PB_EventType_LeftDoubleClick
            gEvt = #_MyGrid_ExitEdit_Vld
            exitEdit = #True
          EndIf
        ElseIf evGt = *mg\Gadget
          ; even though grid is disabled, it's still receiving events!
        Else
          gEvt = #_MyGrid_ExitEdit_Out
          exitEdit = #True
        EndIf
        
    EndSelect
    
  Until exitEdit
  
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Escape     )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Tab        )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Left       )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Right      )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Up         )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Down       )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_PageUp     )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_PageDown   )
  RemoveKeyboardShortcut(winNbr, #PB_Shortcut_Return     )
  
  HideGadget(gdt, 1)
  DisableGadget(*mg\Gadget, 0)
  SetActiveGadget(*mg\Gadget)
  ; entry validation
  If gEvt > #_MyGrid_ExitEdit
    nTxt = GetGadgetText(gdt)
    If nTxt <> oTxt
      _MyGrid_SetCellTextEvent(*mg, r, c, nTxt)
      _MyGrid_DrawCurrentCell(*mg)
    EndIf
  EndIf
  If _MyGrid_IsValidCell(*mg, nr, nc) : _MyGrid_MoveFocus(*mg, nr, nc) : EndIf
  
  Select evMn
    Case #_MyGrid_ExitEdit_Vld_Lt : ProcedureReturn _MyGrid_MoveLeft(*mg, 1)
    Case #_MyGrid_ExitEdit_Vld_Rt : ProcedureReturn _MyGrid_MoveRight(*mg, 1)
    Case #_MyGrid_ExitEdit_Vld_Up : ProcedureReturn _MyGrid_MoveUp(*mg, 1)
    Case #_MyGrid_ExitEdit_Vld_Dn : ProcedureReturn _MyGrid_MoveDown(*mg, 1)
    Case #_MyGrid_ExitEdit_Vld_PUp: ProcedureReturn _MyGrid_MoveUp(*mg, #MyGrid_Scroll_PageSize)
    Case #_MyGrid_ExitEdit_Vld_PDn: ProcedureReturn _MyGrid_MoveDown(*mg, #MyGrid_Scroll_PageSize)
  EndSelect
  
  If gEvt = #_MyGrid_ExitEdit_Out
    PostEvent(evnt, winNbr, evGt, evTy) ; passing event to caller window
  EndIf
  
  ProcedureReturn #False
  
EndProcedure

Procedure.i _MyGrid_UserResize(*mg._MyGrid_Type, x, y)
  ; we resize only if:
  ;       1. we are in the area of col-header
  ;  OR   2. we are in the area of row-header
  ;  OR   3. we are in both col-header and row-header
  ;
  ; if resizing from left/up -> resizing that column/row
  ; if resizing from right/down -> un-hiding any next hidden column/row
  ; DownX, DownY store coord. when resizing started
  ;   
  Protected i, px, py, c, r, nwVal, oAreaRow, oAreaCol, X1, X2, Y1, Y2, crs
  
  px = *mg\DownX
  py = *mg\DownY
  If px = x  And py = y : ProcedureReturn : EndIf
  
  oAreaRow = _MyGrid_AreaResizeRow(*mg, px, py)
  oAreaCol = _MyGrid_AreaResizeCol(*mg, px, py)
  
  FirstElement(*mg\LstAreaCol()) : X1 = *mg\LstAreaCol()\X : X2 = X1 + *mg\LstAreaCol()\Width
  FirstElement(*mg\LstAreaRow()) : Y1 = *mg\LstAreaRow()\Y : Y2 = Y1 + *mg\LstAreaRow()\Height
  
  crs      = GetGadgetAttribute(*mg\Gadget, #PB_Canvas_Cursor)
  
  ; resizing column or unhiding a col that was shrunk to 0 by user
  If oAreaCol >= 0 And Y1 <= y And y < Y2 And crs = #PB_Cursor_LeftRight
    
    SelectElement(*mg\LstAreaCol() , oAreaCol)
    
    If px <= *mg\LstAreaCol()\X + *mg\LstAreaCol()\Width
      c = *mg\LstAreaCol()\Col
      nwVal = *mg\ColWidth(c) + (x - px) : If nwVal < 0 : nwVal = 0 : EndIf
      _MyGrid_ChangeColWidth(*mg, c, nwVal)
    Else
      c = *mg\LstAreaCol()\Col
      For i = *mg\LstAreaCol()\Col+1 To *mg\Cols
        If *mg\ColWidth(i) = 0
          c = i: Break
        EndIf
        If *mg\ColWidth(i) > 0 : Break : EndIf
      Next
      nwVal = *mg\ColWidth(c) + (x - px) : If nwVal < 0 : nwVal = 0 : EndIf
      _MyGrid_ChangeColWidth(*mg, c, nwVal)
    EndIf
    
  EndIf
  
  ; resizing row or unhiding a row that was shrunk to 0 by user
  If oAreaRow >= 0 And X1 <= x And x < X2 And crs = #PB_Cursor_UpDown
    
    SelectElement(*mg\LstAreaRow() , oAreaRow)
    
    If py <= *mg\LstAreaRow()\Y + *mg\LstAreaRow()\Height
      r = *mg\LstAreaRow()\Row
      nwVal = *mg\RowHeight(r) + (y - py) : If nwVal < 0 : nwVal = 0 : EndIf
      _MyGrid_ChangeRowHeight(*mg, r, nwVal)
    Else
      r = *mg\LstAreaRow()\Row
      For i = *mg\LstAreaRow()\Row+1 To *mg\Rows
        If *mg\RowHeight(i) = 0
          r = i: Break
        EndIf
        If *mg\RowHeight(i) > 0 : Break : EndIf
      Next
      nwVal = *mg\RowHeight(r) + (y - py) : If nwVal < 0 : nwVal = 0 : EndIf
      _MyGrid_ChangeRowHeight(*mg, r, nwVal)
    EndIf
    
  EndIf
  
EndProcedure

;-------------------------------------------------------------------------------------------- 
;--- Init and default 
;-------------------------------------------------------------------------------------------- 
Procedure.i _MyGrid_Reset(*mg._MyGrid_Type, Rows, Cols)
  ; Reset everything so Grid can receive/show new data
  Protected i,j
  
  If rows < 0 : rows = 0  : EndIf
  If cols < 0 : cols = 0  : EndIf
  
  *mg\Rows = rows         : Dim *mg\RowHeight(rows)
  *mg\Cols = cols         : Dim *mg\ColWidth(cols) :  Dim *mg\ColID(cols)
  
  *mg\LastIndex = (rows+1) * (cols+1) - 1
  Dim *mg\gData(*mg\LastIndex)
  If ArraySize(*mg\gData()) < 0
    ;Debug "failed to allocate memory for the grid data !... "
    ProcedureReturn 0
  EndIf
  
  ; initializations
  *mg\TopRow              = 1
  *mg\TopCol              = 1
  *mg\Row                 = 1
  *mg\Col                 = 1
  *mg\Row2                = 0
  *mg\Col2                = 0
  
  ;"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  For i=1 To cols
    _MyGrid_SetCellText(*mg, 0, i, "Col " + Str(i))
  Next
  
  For i=1 To rows
    _MyGrid_SetCellText(*mg, i, 0, Str(i))
  Next
  
  _MyGrid_ChangeColWidth(*mg, #MyGrid_RC_Any, #MyGrid_Default_ColWidth)
  _MyGrid_ChangeRowHeight(*mg, #MyGrid_RC_Any, #MyGrid_Default_RowHeight)
  
  *mg\FrozenCol           = 0
  *mg\FrozenRow           = 0
  
  *mg\MoveStatus          = #MyGrid_MouseMove_Nothing
  *mg\DownX               = 0
  *mg\DownY               = 0
  
  *mg\NoRedraw            = #False
  
  *mg\Color_Line          = RGB(230, 230, 230) ;RGB(224, 224, 224)
  *mg\Color_BlockBack     = RGBA(220, 220, 220, 139)
  *mg\Color_FocusBack     = RGB(255, 255, 255)
  *mg\Color_Background    = RGB(242, 242, 242)
  *mg\Color_FocusBorder   = RGB(0, 0, 198)
  
  *mg\WrapText            = #True
  
  ;
  ClearList(*mg\LstMulti())
  
  ClearList( *mg\LstStyle() )
  ClearMap(  *mg\DicStyle() )
  
  *mg\Style_Data_Data     = -1
  *mg\Style_Any_Data      = -1
  *mg\Style_Data_Any      = -1
  
  ; adding one default style applies to the whole grid
  AddElement(*mg\LstStyle())
  *mg\LstStyle()\Aling     = #MyGrid_Align_Left
  *mg\LstStyle()\BackColor = $FFFFFF
  *mg\LstStyle()\ForeColor = $000000
  *mg\LstStyle()\Font      = LoadFont(#PB_Any, "Arial", 8)
  *mg\LstStyle()\CellType  = #MyGrid_CellType_Normal
  *mg\LstStyle()\DataType  = #MyGrid_DataType_Text
  *mg\LstStyle()\Editable  = #False
  *mg\LstStyle()\EditMode  = #MyGrid_Edit_Append
  *mg\LstStyle()\Gradient  = 0
  
  
  *mg\DicStyle(Str(#MyGrid_RC_Any) +":"+Str(#MyGrid_RC_Any)) = 0
  *mg\Style_Any_Any        = 0
  
  ; set min/max/page of scrolls
  _MyGrid_AdjustScrolls(*mg)
  
  ProcedureReturn *mg\LastIndex
  
EndProcedure
Procedure.i _MyGrid_ResetRows(*mg._MyGrid_Type, Rows)
  ; delete all rows (clearing data) and keeps columns unchanged
  Protected i, oRows = *mg\Rows
  
  If Rows < 0 : Rows = 0  : EndIf
  *mg\Rows = Rows         : ReDim *mg\RowHeight(Rows)
  
  *mg\LastIndex = (Rows + 1) * (*mg\Cols + 1) - 1
  ReDim *mg\gData(*mg\LastIndex)
  If ArraySize(*mg\gData()) < 0
    ;Debug "failed to allocate memory for the grid data !... "
    ProcedureReturn
  EndIf
  
  For i = oRows+1 To Rows
    _MyGrid_SetCellText(*mg, i, 0, Str(i))
    *mg\RowHeight(i) = #MyGrid_Default_RowHeight
  Next
  
  If *mg\TopRow > *mg\Rows : *mg\TopRow = *mg\Rows : EndIf
  If *mg\Row    > *mg\Rows : *mg\Row    = *mg\Rows : EndIf
  If *mg\Row2   > *mg\Rows : *mg\Row2   = *mg\Rows : EndIf
  If *mg\TopCol > *mg\Cols : *mg\TopCol = *mg\Cols : EndIf
  If *mg\Col    > *mg\Cols : *mg\Col    = *mg\Cols : EndIf
  If *mg\Col2   > *mg\Cols : *mg\Col2   = *mg\Cols : EndIf
  
  _MyGrid_AdjustScrolls(*mg)      ; set min/max/page of scrolls
  
EndProcedure
Procedure.i _MyGrid_Resize()
  ; internal event handler: resize the grid ... requested by end-user/window resized
  Protected *mg._MyGrid_Type, Gdt, X,Y,W,H
  Gdt = EventGadget()
  *mg = GetGadgetData(Gdt)
  X   = GadgetX(Gdt)
  Y   = GadgetY(Gdt)
  W   = GadgetWidth(Gdt)
  H   = GadgetHeight(Gdt)
  
  ; -- resizing scroll bars 
  If IsGadget(*mg\ColScroll) : W = W - #MyGrid_Scroll_Width : EndIf
  If IsGadget(*mg\RowScroll) : H = H - #MyGrid_Scroll_Width : EndIf
  
  If IsGadget(*mg\ColScroll)
    ResizeGadget( *mg\ColScroll, X, Y + H, W, #MyGrid_Scroll_Width)
  EndIf
  If IsGadget(*mg\RowScroll)
    ResizeGadget( *mg\RowScroll, X + W, Y, #MyGrid_Scroll_Width, H)
  EndIf    
  
  *mg\GadgetW = W
  *mg\GadgetH = H
  *mg\GadgetX = X
  *mg\GadgetY = Y
  
  _MyGrid_Draw(*mg)
  _MyGrid_AdjustScrolls(*mg)
  
EndProcedure

;-------------------------------------------------------------------------------------------- 
;--- Interface / Exposed - works with PB Gadget number
;    Only exposed routines should call _MyGrid_Draw()
;-------------------------------------------------------------------------------------------- 
Procedure.i MyGrid_ChangeTopRow(Gdt, TopRow)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If *mg\TopRow <> TopRow
    *mg\TopRow = TopRow
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure
Procedure.i MyGrid_ChangeTopCol(Gdt, TopCol)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If *mg\TopCol <> TopCol
    *mg\TopCol = TopCol
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure

Procedure.i MyGrid_MoveUp(   Gdt, xStep, moveWhat)
  If _MyGrid_MoveUp(GetGadgetData(Gdt), xStep, moveWhat) : _MyGrid_Draw(GetGadgetData(Gdt)) : EndIf
EndProcedure
Procedure.i MyGrid_MoveDown( Gdt, xStep, moveWhat)
  If _MyGrid_MoveDown(GetGadgetData(Gdt), xStep, moveWhat) : _MyGrid_Draw(GetGadgetData(Gdt)) : EndIf
EndProcedure
Procedure.i MyGrid_MoveLeft( Gdt, xStep, moveWhat)
  If _MyGrid_MoveLeft(GetGadgetData(Gdt), xStep, moveWhat) : _MyGrid_Draw(GetGadgetData(Gdt)) : EndIf
EndProcedure
Procedure.i MyGrid_MoveRight(Gdt, xStep, moveWhat)
  If _MyGrid_MoveRight(GetGadgetData(Gdt), xStep, moveWhat) : _MyGrid_Draw(GetGadgetData(Gdt)) : EndIf
EndProcedure


Procedure.i MyGrid_ShowCell(Gdt.i, Row, Col, SetCellFocus = #False)
  ; makes sure cell defined by (Row,Col) is visible on screen - scrolls if need be
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected tr, tc
  
  If _MyGrid_IsValidCell(*mg, Row, Col) = #False : ProcedureReturn #False : EndIf
  
  If *mg\RowHeight(Row) <= 0  : ProcedureReturn #False : EndIf
  If *mg\ColWidth(Col)  <= 0  : ProcedureReturn #False : EndIf
  
  tr = _MyGrid_NearestTopRow(*mg, Row)
  tc = _MyGrid_NearestTopCol(*mg, Col)
  If tr <> *mg\TopRow Or tc <> *mg\TopCol
    *mg\TopRow = tr   : *mg\TopCol = tc
    If SetCellFocus
      *mg\Row = row : *mg\Col = col
    EndIf
    _MyGrid_Draw(*mg)
  Else
    _MyGrid_MoveFocus(*mg, Row, Col)
  EndIf
  
  ProcedureReturn #True
  
EndProcedure
Macro       MyGrid_FocusCell(Gdt, Row, Col)
  ; moves the focus from current cell to the new one defind by param
  MyGrid_ShowCell(Gdt, Row, Col, #True)
  
EndMacro

Procedure.i MyGrid_NoRedraw(Gdt)
  ; stops drawing - useful when many settings that should yield a drawing each are 
  ; grouped together ... once applying those settings is over, we draw once only
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  *mg\NoRedraw = #True
EndProcedure
Procedure.i MyGrid_Redraw(Gdt)
  ; forces a draw now
  Protected *mg._MyGrid_Type = GetGadgetData(gdt)
  *mg\NoRedraw = #False
  _MyGrid_Draw(*mg)
  
EndProcedure

;---- ********************** some Setters/Getters:

Procedure.i MyGrid_IsValidCell(Gdt.i, Row, Col)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If _MyGrid_IsValidCell(*mg, Row, Col) : ProcedureReturn #True : EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i MyGrid_GetAttribute(Gdt.i, Attribute = #MyGrid_Att_Row, RowOrCol = 0)
  Protected i,n, *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  Select Attribute
    Case #MyGrid_Att_Row		: ProcedureReturn *mg\Row
    Case #MyGrid_Att_Col        : ProcedureReturn *mg\Col
    Case #MyGrid_Att_RowCount   : ProcedureReturn *mg\Rows
    Case #MyGrid_Att_ColCount   : ProcedureReturn *mg\Cols
    Case #MyGrid_Att_RowHeight
      If RowOrCol <= *mg\Rows And RowOrCol >= 0 
        ProcedureReturn *mg\RowHeight(RowOrCol)
      EndIf
      
    Case #MyGrid_Att_ColWdith
      If RowOrCol <= *mg\Cols And RowOrCol >= 0 
        ProcedureReturn *mg\ColWidth(RowOrCol)
      EndIf
    Case #MyGrid_Att_TopRow		: ProcedureReturn *mg\TopRow
    Case #MyGrid_Att_TopCol		: ProcedureReturn *mg\TopCol
    Case #MyGrid_Att_FrozenRow	: ProcedureReturn *mg\FrozenRow
    Case #MyGrid_Att_FrozenCol	: ProcedureReturn *mg\FrozenCol
    Case #MyGrid_Att_Block_Row2 : ProcedureReturn *mg\Row2
    Case #MyGrid_Att_Block_Col2 : ProcedureReturn *mg\Col2
    Case #MyGrid_Att_NonHiddenRow
      For i=1 To *mg\Rows
        If *mg\RowHeight(i) <> -1 : n = n + 1: EndIf
      Next
      ProcedureReturn n
      
    Case #MyGrid_Att_NonHiddenCol
      For i=1 To *mg\Cols
        If *mg\ColWidth(i) <> -1 : n = n + 1: EndIf
      Next
      ProcedureReturn n
      
    Case #MyGrid_Att_ChangedRow : ProcedureReturn *mg\ChangedRow
    Case #MyGrid_Att_ChangedCol : ProcedureReturn *mg\ChangedCol
      
    Case #MyGrid_Att_ClickedRow : ProcedureReturn *mg\ClickedRow
    Case #MyGrid_Att_ClickedCol : ProcedureReturn *mg\ClickedCol
      
    Case #MyGrid_Att_GadgetRowScroll    : ProcedureReturn *mg\RowScroll
    Case #MyGrid_Att_GadgetColScroll    : ProcedureReturn *mg\ColScroll
      
  EndSelect
  
  ProcedureReturn -1
  
EndProcedure
Procedure.s MyGrid_LastChangedCellText(Gdt.i)
  Protected i,n, *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  ProcedureReturn *mg\ChangedTxt
  
EndProcedure
Procedure.i MyGrid_ClearLastChange(Gdt.i)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  *mg\ChangedRow = -1
  *mg\ChangedCol = -1
  *mg\ChangedTxt = ""
  
EndProcedure
Procedure.i MyGrid_ClearLastClick(Gdt.i)
  Protected i,n, *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  *mg\ClickedRow = -1
  *mg\ClickedCol = -1
  
EndProcedure

;--- Grid level
Procedure.i MyGrid_SetColorAttribute(Gdt.i, Attribute = #MyGrid_Color_Line, Value = $CCCCCC)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  Select Attribute
    Case #MyGrid_Color_Line          : *mg\Color_Line = Value
    Case #MyGrid_Color_Background    : *mg\Color_Background = Value
    Case #MyGrid_Color_FocusBack     : *mg\Color_FocusBack = Value
    Case #MyGrid_Color_FocusBorder   : *mg\Color_FocusBorder = Value
    Case #MyGrid_Color_BlockBack     : *mg\Color_BlockBack = Value
      
  EndSelect
  
EndProcedure
Procedure.i MyGrid_GetColorAttribute(Gdt.i, Attribute = #MyGrid_Color_Line)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  Select Attribute
    Case #MyGrid_Color_Line          : ProcedureReturn *mg\Color_Line
    Case #MyGrid_Color_Background    : ProcedureReturn *mg\Color_Background
    Case #MyGrid_Color_FocusBack     : ProcedureReturn *mg\Color_FocusBack
    Case #MyGrid_Color_FocusBorder   : ProcedureReturn *mg\Color_FocusBorder
    Case #MyGrid_Color_BlockBack     : ProcedureReturn *mg\Color_BlockBack
      
  EndSelect
  
  ProcedureReturn -1
  
EndProcedure

Procedure.i MyGrid_AttachPopup(Gdt.i, Popup.i)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  *mg\AttachedPopupMenu = Popup
  
EndProcedure
Procedure.i MyGrid_ReDefine(Gdt.i, Rows, Cols)
  Protected i, *mg._MyGrid_Type = GetGadgetData(gdt)
  
  _MyGrid_Reset(*mg, Rows, Cols)
  _MyGrid_Draw(*mg)
  
EndProcedure
Procedure.i MyGrid_ReDefineRows(Gdt.i, Rows)
  Protected i, *mg._MyGrid_Type = GetGadgetData(gdt)
  
  _MyGrid_ResetRows(*mg, Rows)
  _MyGrid_Draw(*mg)
  
EndProcedure
Procedure   MyGrid_Resize(Gdt.i, X,Y,W,H)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If X = #PB_Ignore : X = *mg\GadgetX : EndIf
  If Y = #PB_Ignore : Y = *mg\GadgetY : EndIf
  If W = #PB_Ignore : W = *mg\GadgetW : EndIf
  If H = #PB_Ignore : H = *mg\GadgetH : EndIf
  
  ; -- resizing scroll bars 
  If IsGadget(*mg\ColScroll) : W = W - #MyGrid_Scroll_Width : EndIf
  If IsGadget(*mg\RowScroll) : H = H - #MyGrid_Scroll_Width : EndIf
  
  If IsGadget(*mg\ColScroll)
    ResizeGadget( *mg\ColScroll, X, Y + H, W, #MyGrid_Scroll_Width)
  EndIf
  If IsGadget(*mg\RowScroll)
    ResizeGadget( *mg\RowScroll, X + W, Y, #MyGrid_Scroll_Width, H)
  EndIf    
  
  ResizeGadget(Gdt, X, Y , W, H)
  
  *mg\GadgetW = W
  *mg\GadgetH = H
  *mg\GadgetX = X
  *mg\GadgetY = Y
  
  _MyGrid_Draw(*mg)
  _MyGrid_AdjustScrolls(*mg)
  
EndProcedure
Procedure   MyGrid_Hide(Gdt.i, State = 0)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  HideGadget(Gdt, State)
  If IsGadget(*mg\ColScroll) : HideGadget(*mg\ColScroll, State) : EndIf
  If IsGadget(*mg\RowScroll) : HideGadget(*mg\RowScroll, State) : EndIf
  If IsGadget(*mg\TxtEdit)   : HideGadget(*mg\TxtEdit, State)   : EndIf
  If IsGadget(*mg\CmbEdit)   : HideGadget(*mg\CmbEdit, State)   : EndIf
  
EndProcedure
Procedure   MyGrid_Free(Gdt.i)
  Protected *mg._MyGrid_Type
  
  If IsGadget(Gdt)
    *mg = GetGadgetData(Gdt)
    FreeGadget(Gdt)
    If IsGadget(*mg\ColScroll) : FreeGadget(*mg\ColScroll) : EndIf
    If IsGadget(*mg\RowScroll) : FreeGadget(*mg\RowScroll) : EndIf
    If IsGadget(*mg\TxtEdit)   : FreeGadget(*mg\TxtEdit)   : EndIf
    If IsGadget(*mg\CmbEdit)   : FreeGadget(*mg\CmbEdit)   : EndIf
    FreeMemory(*mg)
  EndIf
  
EndProcedure

Procedure.i MyGrid_SetText(Gdt.i, Row.i, Col.i, Txt.s)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If _MyGrid_IsValidCell(*mg, Row, Col)
    _MyGrid_SetCellText(*mg, Row, Col, Txt)
  EndIf
  
EndProcedure
Procedure.s MyGrid_GetText(Gdt.i, Row.i, Col.i)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If _MyGrid_IsValidCell(*mg, Row, Col)
    ProcedureReturn _MyGrid_GetCellText(*mg, Row, Col)
  EndIf
  ProcedureReturn ""
  
EndProcedure

;--- Style: we revise Last Style only (eaiser to remember)
Procedure.i MyGrid_AssignStyle(Gdt, GRow, GCol, Style)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  *mg\DicStyle(Str(GRow) + ":" + Str(GCol)) = Style
  If (GRow = #MyGrid_RC_Data) And (GCol = #MyGrid_RC_Data) : *mg\Style_Data_Data = Style : EndIf
  If (GRow = #MyGrid_RC_Data) And (GCol = #MyGrid_RC_Any ) : *mg\Style_Data_Any  = Style : EndIf
  If (GRow = #MyGrid_RC_Any ) And (GCol = #MyGrid_RC_Data) : *mg\Style_Any_Data  = Style : EndIf
  If (GRow = #MyGrid_RC_Any ) And (GCol = #MyGrid_RC_Any ) : *mg\Style_Any_Any   = Style : EndIf
  
EndProcedure
Procedure.i MyGrid_AddNewStyle(Gdt, GRow = -1, GCol = -1)
  ; adds a new style that's a replica of 1st Style AA
  Protected Style, *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected nwStyle._MyGrid_CellStyle_Type
  
  If FirstElement(*mg\LstStyle())
    CopyStructure(@*mg\LstStyle(), @nwStyle, _MyGrid_CellStyle_Type)
    LastElement(*mg\LstStyle())
    AddElement(*mg\LstStyle())
    CopyStructure(@nwStyle, @*mg\LstStyle(), _MyGrid_CellStyle_Type)
    Style = ListIndex(*mg\LstStyle())
    ; assigns the new style to (GRow, GCol) if specified
    If (GRow <> -1) And (GCol <> -1)
      MyGrid_AssignStyle(Gdt, GRow, GCol, Style)
    EndIf
    
    ProcedureReturn Style
  EndIf
  ProcedureReturn -1
  
EndProcedure

Procedure.i MyGrid_LastStyle_Align(Gdt, Value = #MyGrid_Align_Left)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\Aling = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_BackColor(Gdt, Color)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\BackColor = Color : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_ForeColor(Gdt, Color)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\ForeColor = Color : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_Font(Gdt, FontNumber)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\Font = FontNumber : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_CellType(Gdt, Value = #MyGrid_CellType_Normal)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\CellType = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_DataType(Gdt, Value = #MyGrid_DataType_Text)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\DataType = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_Editable(Gdt, Value = #True)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\Editable = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_EditMode(Gdt, Value = #MyGrid_Edit_Over)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\EditMode = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_Gradient(Gdt, Value = #True)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If LastElement(*mg\LstStyle()) : *mg\LstStyle()\Gradient = Value : EndIf
  
EndProcedure
Procedure.i MyGrid_LastStyle_Items(Gdt, Items.s, ItemSep.s)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected iWrd, nWrd, Dim tWrd.s(0)
  
  If LastElement(*mg\LstStyle())
    ClearList(*mg\LstStyle()\Item())
    nWrd = MySplitString(Items, ItemSep, tWrd())
    For iWrd = 1 To nWrd
      AddElement(*mg\LstStyle()\Item())
      *mg\LstStyle()\Item() = tWrd(iWrd)
    Next
  EndIf
  
EndProcedure

;--- For Columns
Procedure.i MyGrid_Col_SetColID(Gdt.i, Col.i, ColID.s)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If (Col <= *mg\Cols) And (Col >= 0)
    *mg\DicColID(UCase(ColID)) = Col
    *mg\ColID(Col) = ColID
  EndIf
  
EndProcedure
Procedure.i MyGrid_ColNumberOfColID(Gdt.i, ColID.s)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If FindMapElement(*mg\DicColID(), UCase(ColID))
    ProcedureReturn *mg\DicColID()
  EndIf
  ProcedureReturn -1
  
EndProcedure
Procedure.s MyGrid_ColIdOfColNumber(Gdt.i, Col)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If (Col <= *mg\Cols) And (Col >= 0) : ProcedureReturn *mg\ColID(Col) : EndIf
  ProcedureReturn ""
  
EndProcedure

Procedure.i MyGrid_Col_ChangeWidth(Gdt.i, GCol.i, Width.i = #MyGrid_Default_ColWidth)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  _MyGrid_ChangeColWidth(*mg, GCol, Width)
  _MyGrid_Draw(*mg)
  
EndProcedure
Procedure.i MyGrid_Col_Hide(Gdt.i, GCol.i, State)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If State
    _MyGrid_ChangeColWidth(*mg, GCol, -1)   ; hidden by application cannot be un-hidden by user
    _MyGrid_Draw(*mg)
  Else
    _MyGrid_ChangeColWidth(*mg, GCol, #MyGrid_Default_ColWidth)
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure
Procedure.i MyGrid_Col_AutoWidth(Gdt.i, GCol)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected i, SFont, mxWdh, wdh, iC, C1, C2, wrd.s, rdrw
  
  If Not _MyGrid_IsValidGenericCol(*mg, GCol) : ProcedureReturn : EndIf
  
  If GCol >= 0                : C1 = GCol :  C2 = GCol     : EndIf
  If GCol = #MyGrid_RC_Data   : C1 = 1    :  C2 = *mg\Cols : EndIf
  If GCol = #MyGrid_RC_Any    : C1 = 0    :  C2 = *mg\Cols : EndIf
  
  ; dummy StartDrawing to measure text-width
  If StartDrawing(CanvasOutput(*mg\Gadget)) 
    
    For iC = C1 To C2
      If *mg\ColWidth( iC) = -1 : Continue : EndIf
      
      mxWdh = 0
      For i = 0 To *mg\Rows
        wrd = _MyGrid_GetCellText(*mg, i, iC)
        If wrd <> ""
          __MyGrid_SelectStyle(*mg, i, iC)
          SFont = *mg\LstStyle()\Font
          If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
          wdh = TextWidth(wrd)
          If wdh > mxWdh : mxWdh = wdh : EndIf
        EndIf
      Next i
      mxWdh = mxWdh + (2*#MyGrid_Text_MarginX)
      
      If *mg\ColWidth( iC) <> mxWdh
        If mxWdh > 0.9 * *mg\GadgetW : mxWdh = 0.9 * *mg\GadgetW : EndIf
        _MyGrid_ChangeColWidth(*mg, iC, mxWdh)
        rdrw = #True
      EndIf
      
    Next iC
    
    StopDrawing()
  EndIf
  If rdrw : _MyGrid_Draw(*mg) : EndIf
  
EndProcedure
Procedure.i MyGrid_Col_Freeze(Gdt.i, Col.i)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If Col <= *mg\Cols And Col >= 0
    *mg\FrozenCol = Col
    _MyGrid_AdjustScrolls(*mg)
  EndIf
  
EndProcedure


;--- For Rows only
Procedure.i MyGrid_Row_ChangeHeight(Gdt.i, GRow.i, Height.i = #MyGrid_Default_RowHeight)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  _MyGrid_ChangeRowHeight(*mg, GRow, Height)
  _MyGrid_Draw(*mg)
  
EndProcedure
Procedure.i MyGrid_Row_Hide(Gdt.i, GRow.i, State)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If State
    _MyGrid_ChangeRowHeight(*mg, GRow, -1)  ; hidden by application cannot be un-hidden by user
    _MyGrid_Draw(*mg)
  Else
    _MyGrid_ChangeRowHeight(*mg, GRow, #MyGrid_Default_RowHeight)
    _MyGrid_Draw(*mg)
  EndIf
  
EndProcedure
Procedure.i MyGrid_Row_AutoHeight(Gdt.i, GRow)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected i, SFont,  mxHgt, hgt, iR, R1, R2, wrd.s, rdrw
  
  If Not _MyGrid_IsValidGenericRow(*mg, GRow) : ProcedureReturn : EndIf
  
  If GRow >= 0                : R1 = GRow :  R2 = GRow     : EndIf
  If GRow = #MyGrid_RC_Data   : R1 = 1    :  R2 = *mg\Rows : EndIf
  If GRow = #MyGrid_RC_Any    : R1 = 0    :  R2 = *mg\Rows : EndIf
  
  ; dummy StartDrawing to measure text-width
  If StartDrawing(CanvasOutput(*mg\Gadget)) 
    
    For iR = R1 To R2
      If *mg\RowHeight( iR) = -1 : Continue : EndIf
      
      mxHgt = 0
      For i = 0 To *mg\Cols
        wrd = _MyGrid_GetCellText(*mg, iR, i)
        If wrd <> ""
          __MyGrid_SelectStyle(*mg, iR, i)
          SFont = *mg\LstStyle()\Font
          If IsFont(SFont) : DrawingFont(FontID(SFont)) : EndIf
          hgt = TextHeight(wrd)
          If hgt > mxHgt : mxHgt = hgt : EndIf
        EndIf
      Next i
      mxHgt = mxHgt + (2*#MyGrid_Text_MarginY)
      
      If *mg\RowHeight(iR) <> mxHgt
        If mxHgt > 0.9 * *mg\GadgetH : mxHgt = 0.9 * *mg\GadgetH : EndIf
        _MyGrid_ChangeRowHeight(*mg, iR, mxHgt)
        rdrw = #True
      EndIf
      
    Next iR
    
    StopDrawing()
  EndIf
  If rdrw : _MyGrid_Draw(*mg) : EndIf
  
EndProcedure
Procedure.i MyGrid_Row_Freeze(Gdt.i, Row.i)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If Row <= *mg\Rows And Row >= 0
    *mg\FrozenRow = Row
    _MyGrid_AdjustScrolls(*mg)
  EndIf
  
EndProcedure

Procedure.i MyGrid_MergeCells(Gdt, Row1,Col1, Row2,Col2)
  ; return the index of the multi-cell in LstMulti()
  ; if Style = -1 ---> multi-cell will receive the style of its upper-left cell
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected iR, iC, multi
  
  If Row1 > Row2 : Swap Row1 , Row2 : EndIf
  If Col1 > Col2 : Swap Col1 , Col2 : EndIf
  If Row1 = Row2 And Col1 = Col2 : ProcedureReturn -1 : EndIf
  
  If _MyGrid_IsValidCell(*mg, Row1, Col1) And _MyGrid_IsValidCell(*mg, Row2, Col2)
    
    ForEach *mg\LstMulti()
      If BlocksHaveIntersection(*mg\LstMulti()\R1, *mg\LstMulti()\R2, *mg\LstMulti()\C1, *mg\LstMulti()\C2, Row1, Row2, Col1, Col2)
        ProcedureReturn -1 ; we stop merging! 2 multis cant overlap
      EndIf
    Next
    
    AddElement( *mg\LstMulti() )
    multi = ListIndex(*mg\LstMulti())
    
    *mg\LstMulti()\R1 = Row1
    *mg\LstMulti()\R2 = Row2
    *mg\LstMulti()\C1 = Col1
    *mg\LstMulti()\C2 = Col2
    
    ProcedureReturn multi
  EndIf
  
  ProcedureReturn -1
  
EndProcedure
Procedure.i MyGrid_UnMergeCells(Gdt, Row,Col)
  ; un-merge cells ... (Row, Col) is any cell member of the multi-cell
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected iR, iC, multi
  
  If _MyGrid_IsValidCell(*mg, Row, Col)
    multi = _MyGrid_MultiOfCell(*mg, Row, Col)
    If multi >= 0 
      SelectElement(*mg\LstMulti() , multi)
      DeleteElement(*mg\LstMulti())
    EndIf
  EndIf
  
EndProcedure

Procedure.i MyGrid_HasBlock(Gdt)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If _MyGrid_HasBlock(*mg) : ProcedureReturn #True : EndIf
  
EndProcedure
Procedure.i MyGrid_ClearBlock(Gdt)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  If _MyGrid_HasBlock(*mg)
    _MyGrid_ResetBlock(*mg)
    _MyGrid_Draw(*mg)
  Else
    _MyGrid_ResetBlock(*mg)
  EndIf
  
EndProcedure
Procedure.i MyGrid_DefineBlock(Gdt, Row1,Col1, Row2,Col2)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  
  _MyGrid_StartBlock(*mg, Row1,Col1, Row2,Col2)
  _MyGrid_Draw(*mg)
  
EndProcedure
Procedure.i MyGrid_SelectAll(Gdt)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected Row1 = 1, Col1 = 1, Row2 = *mg\Rows, Col2 = *mg\Cols
  
  _MyGrid_StartBlock(*mg, Row1,Col1, Row2,Col2)
  _MyGrid_Draw(*mg)
  
EndProcedure

; --- Event Manager: all events are processed here!
Procedure.i MyGrid_ManageEvent(Gdt.i, eType)
  Protected *mg._MyGrid_Type = GetGadgetData(Gdt)
  Protected ky,mf, prvState,mx,my,x,y,w,h,ar,ac,col,row,mv,dlt,i,keepOn,crs
  
  Select eType
      
    Case #PB_EventType_KeyDown
      ky = GetGadgetAttribute(gdt, #PB_Canvas_Key )
      mf = GetGadgetAttribute(gdt, #PB_Canvas_Modifiers )
      
      If (mf & #PB_Canvas_Shift) = #PB_Canvas_Shift
        ; navigation key + shift => start a new block And/Or extend current block
        If (mf & #PB_Canvas_Control) = #PB_Canvas_Control
          Select ky
            Case #PB_Shortcut_Left  : MyGrid_MoveLeft( Gdt, *mg\Cols, #MyGrid_Move_Block)
            Case #PB_Shortcut_Right : MyGrid_MoveRight(Gdt, *mg\Cols, #MyGrid_Move_Block)
            Case #PB_Shortcut_Up    : MyGrid_MoveUp(   Gdt, *mg\Rows, #MyGrid_Move_Block)
            Case #PB_Shortcut_Down  : MyGrid_MoveDown( Gdt, *mg\Rows, #MyGrid_Move_Block)
            Case #PB_Shortcut_Home
              MyGrid_MoveUp(  Gdt, *mg\Rows, #MyGrid_Move_Block)
              MyGrid_MoveLeft(Gdt, *mg\Cols, #MyGrid_Move_Block)
            Case #PB_Shortcut_End
              MyGrid_MoveDown( Gdt, *mg\Rows, #MyGrid_Move_Block)
              MyGrid_MoveRight(Gdt, *mg\Cols, #MyGrid_Move_Block)
          EndSelect
        Else
          Select ky
            Case #PB_Shortcut_Left  : MyGrid_MoveLeft( Gdt, 1, #MyGrid_Move_Block)
            Case #PB_Shortcut_Right : MyGrid_MoveRight(Gdt, 1, #MyGrid_Move_Block)
            Case #PB_Shortcut_Up    : MyGrid_MoveUp(   Gdt, 1, #MyGrid_Move_Block)
            Case #PB_Shortcut_Down  : MyGrid_MoveDown( Gdt, 1, #MyGrid_Move_Block)
            Case #PB_Shortcut_PageUp : MyGrid_MoveUp(   Gdt, #MyGrid_Scroll_PageSize, #MyGrid_Move_Block)
            Case #PB_Shortcut_PageDown  : MyGrid_MoveDown( Gdt, #MyGrid_Scroll_PageSize, #MyGrid_Move_Block)
          EndSelect
        EndIf
        
      Else                ; >>>>> no shift key and no control --> block de-selection
        
        If (mf & #PB_Canvas_Control) <> #PB_Canvas_Control : MyGrid_ClearBlock(gdt) : EndIf
        
        If (mf & #PB_Canvas_Control) = #PB_Canvas_Control
          Select ky
            Case #PB_Shortcut_Left   : MyGrid_FocusCell(gdt, *mg\Row, *mg\FrstTopCol)
            Case #PB_Shortcut_Right  : MyGrid_FocusCell(gdt, *mg\Row, *mg\LastVisCol)
            Case #PB_Shortcut_Up     : MyGrid_FocusCell(gdt, *mg\FrstTopRow, *mg\Col)
            Case #PB_Shortcut_Down   : MyGrid_FocusCell(gdt, *mg\LastVisRow, *mg\Col)
            Case #PB_Shortcut_Home   : MyGrid_FocusCell(gdt, *mg\FrstTopRow, *mg\FrstTopCol)
            Case #PB_Shortcut_End    : MyGrid_FocusCell(gdt, *mg\LastVisRow, *mg\LastVisCol)
          EndSelect
        Else
          Select ky
            Case #PB_Shortcut_Left  : MyGrid_MoveLeft( Gdt, 1, #MyGrid_Move_Focus)
            Case #PB_Shortcut_Right : MyGrid_MoveRight(Gdt, 1, #MyGrid_Move_Focus)
            Case #PB_Shortcut_Up    : MyGrid_MoveUp(   Gdt, 1, #MyGrid_Move_Focus)
            Case #PB_Shortcut_Down  : MyGrid_MoveDown( Gdt, 1, #MyGrid_Move_Focus)
            Case #PB_Shortcut_PageUp : MyGrid_MoveUp(  Gdt, #MyGrid_Scroll_PageSize, #MyGrid_Move_Focus)
            Case #PB_Shortcut_PageDown  : MyGrid_MoveDown( Gdt, #MyGrid_Scroll_PageSize, #MyGrid_Move_Focus)
            Case #PB_Shortcut_Tab   : MyGrid_MoveRight(Gdt, 1, #MyGrid_Move_Focus)
              
            Case #PB_Shortcut_Delete, #PB_Shortcut_Back
              __MyGrid_SelectStyle(*mg, *mg\Row, *mg\Col)
              If *mg\LstStyle()\Editable
                _MyGrid_SetCellTextEvent(*mg, *mg\Row, *mg\Col, "")
                _MyGrid_DrawCurrentCell(*mg)
              EndIf
              
            Case #PB_Shortcut_Return
              ; text input takes place in current cell regardless of mouse position
              If MyGrid_ShowCell(gdt, *mg\Row, *mg\Col)
                If _MyGrid_ManageEdit(*mg , "", #True, #False) : _MyGrid_Draw(*mg) : EndIf
              EndIf
              
          EndSelect
        EndIf
        
      EndIf
      
      
    Case #PB_EventType_Input ;, #PB_EventType_LeftDoubleClick
      ; text input takes place in current cell regardless of mouse position
      MyGrid_ClearBlock(gdt)
      If MyGrid_ShowCell(gdt, *mg\Row, *mg\Col)
        If _MyGrid_ManageEdit(*mg , Chr(GetGadgetAttribute(gdt, #PB_Canvas_Input)), #False, #False ) : _MyGrid_Draw(*mg) : EndIf
      EndIf
      
    Case #PB_EventType_MouseWheel
      dlt = GetGadgetAttribute(gdt, #PB_Canvas_WheelDelta)
      ; when moving wheel down towards me (like pressing key-down) => dlt < 0
      ; when moving wheel up   towards screen (like pressing key-up) => dlt > 0
      If dlt < 0
        MyGrid_MoveDown(gdt, -dlt, #MyGrid_Move_TopRC)
      ElseIf dlt > 0
        MyGrid_MoveUp(gdt, dlt, #MyGrid_Move_TopRC)
      EndIf
      
    Case #PB_EventType_LeftDoubleClick
      ; text input takes place in current cell regardless of mouse position
      x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
      y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
      ac = _MyGrid_AreaCol_Of_X(*mg, x)
      ar = _MyGrid_AreaRow_Of_Y(*mg, y)
      If ar > 0 And ac > 0
        ; cell area
        MyGrid_ClearBlock(gdt)
        If MyGrid_ShowCell(gdt, *mg\Row, *mg\Col)
          If _MyGrid_ManageEdit(*mg , "", #True, #False) : _MyGrid_Draw(*mg) : EndIf
        EndIf
        
      Else
        ; header area ?
        ac = _MyGrid_AreaResizeCol(*mg, x, y)
        If ac >= 0
          SelectElement(*mg\LstAreaCol() , ac)
          MyGrid_Col_AutoWidth(gdt, *mg\LstAreaCol()\Col)
        Else
          ar = _MyGrid_AreaResizeRow(*mg, x, y)
          If ar >= 0
            SelectElement(*mg\LstAreaRow() , ar)
            MyGrid_Row_AutoHeight(gdt, *mg\LstAreaRow()\Row)
          EndIf
        EndIf
        
      EndIf
      
    Case #PB_EventType_MouseEnter
    Case #PB_EventType_MouseMove 
      ; 1. Change cursor to allow resizing: Col/Row
      ; 2. Resizing Col/Row
      ; 3. Scrolling Up/Down
      ; 4. selecting a block of cell
      x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
      y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
      
      If GetGadgetAttribute(gdt, #PB_Canvas_Buttons) = #PB_Canvas_LeftButton
        ; continuing the current move-action if any ... or starting new one
        mv = *mg\MoveStatus
        Select mv
          Case #MyGrid_MouseMove_Nothing
            ac = _MyGrid_AreaCol_Of_X(*mg, x)
            ar = _MyGrid_AreaRow_Of_Y(*mg, y)
            
            If ar > 0 And ac > 0 
              If *mg\DownAreaRow >= 0 And *mg\DownAreaCol >= 0 And (*mg\DownAreaRow <> ar Or *mg\DownAreaCol <> ac)
                *mg\MoveStatus = #MyGrid_MouseMove_Select
                _MyGrid_StartBlock(*mg)
              EndIf
              
            ElseIf _MyGrid_OverResizeCol(*mg, x, y)
              *mg\MoveStatus = #MyGrid_MouseMove_Resize
              
            ElseIf _MyGrid_OverResizeRow(*mg, x, y)
              *mg\MoveStatus = #MyGrid_MouseMove_Resize
              
            ElseIf ar = 0 And ac > 0
              *mg\MoveStatus = #MyGrid_MouseMove_Select
              SelectElement(*mg\LstAreaCol() , ac)
              _MyGrid_StartBlock(*mg, *mg\FrstVisRow, *mg\LstAreaCol()\Col, *mg\LastVisRow, *mg\LstAreaCol()\Col)
              _MyGrid_Draw(*mg)
              
            ElseIf ar > 0 And ac = 0
              *mg\MoveStatus = #MyGrid_MouseMove_Select
              SelectElement(*mg\LstAreaRow() , ar)
              _MyGrid_StartBlock(*mg, *mg\LstAreaRow()\Row, *mg\FrstVisCol, *mg\LstAreaRow()\Row, *mg\LastVisCol)
              _MyGrid_Draw(*mg)
              
            ElseIf ar = 0 And ac = 0
              *mg\MoveStatus = #MyGrid_MouseMove_Select
              _MyGrid_StartBlock(*mg, *mg\FrstVisRow, *mg\FrstVisCol, *mg\LastVisRow, *mg\LastVisCol)
              _MyGrid_Draw(*mg)
              
            EndIf
            
          Case #MyGrid_MouseMove_Select
            If _MyGrid_ExtendBlock_XY(*mg, x, y) : _MyGrid_Draw(*mg) : EndIf
            
          Case #MyGrid_MouseMove_Resize
        EndSelect
        
      Else
        
        *mg\MoveStatus = #MyGrid_MouseMove_Nothing ; no move-action
        _MyGrid_ChangeMouse(*mg, x, y)
        
      EndIf
      
    Case #PB_EventType_MouseLeave
      
    Case #PB_EventType_LeftButtonUp
      x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
      y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
      
      mv = *mg\MoveStatus
      Select mv
        Case #MyGrid_MouseMove_Nothing
          ; a simple click in a cell
          row = _MyGrid_Row_Of_Y(*mg, y)
          col = _MyGrid_Col_Of_X(*mg, x)
          If row = *mg\Row And col = *mg\Col
            If _MyGrid_ManageEdit(*mg, "", #False, #True) : _MyGrid_Draw(*mg) : EndIf
          EndIf
          
        Case #MyGrid_MouseMove_Select
        Case #MyGrid_MouseMove_Resize
          
          _MyGrid_UserResize(*mg, x, y)
          _MyGrid_Draw(*mg)
          
          *mg\MoveStatus = #MyGrid_MouseMove_Nothing
          
      EndSelect
      _MyGrid_ResetDownClick(*mg)
      
    Case #PB_EventType_LeftButtonDown
      x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
      y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
      ac = _MyGrid_AreaCol_Of_X(*mg, x)
      ar = _MyGrid_AreaRow_Of_Y(*mg, y)
      *mg\DownX = x : *mg\DownY = y
      *mg\DownAreaRow = ar : *mg\DownAreaCol = ac
      If ar > 0 And ac > 0
        MyGrid_ClearBlock(gdt)
        SelectElement(*mg\LstAreaRow() , ar)
        SelectElement(*mg\LstAreaCol() , ac)
        MyGrid_FocusCell(gdt, *mg\LstAreaRow()\Row, *mg\LstAreaCol()\Col)
      EndIf
      
    Case #PB_EventType_RightButtonDown
      If IsMenu(*mg\AttachedPopupMenu)
        ; launches the attachd popup menu - that's all! selected menu-items will need be handled by caller (via EvenMenu())!
        x = GetGadgetAttribute(gdt, #PB_Canvas_MouseX)
        y = GetGadgetAttribute(gdt, #PB_Canvas_MouseY)
        If _MyGrid_OverCellArea(*mg, x, y)
          If Not _MyGrid_OverBlock(*mg, x, y) : MyGrid_ClearBlock(gdt) : EndIf
          row = _MyGrid_Row_Of_Y(*mg, y)
          col = _MyGrid_Col_Of_X(*mg, x)
          MyGrid_FocusCell(gdt, row, col)
          ;DisplayPopupMenu(*mg\AttachedPopupMenu, WindowID(*mg\Window), x, y)
          DisplayPopupMenu(*mg\AttachedPopupMenu, WindowID(*mg\Window))
        EndIf
      EndIf
      
      
    Default ; any other event is simply ignored ... for now
      ProcedureReturn #False 
  EndSelect
  
EndProcedure

;--------------------------- New Grid 
Procedure.i MyGrid_New(WinNbr, Gadget, X, Y, W, H, Rows = 500, Cols = 100, DoNotDraw = #False, NoScrollBars = #False)
  Protected *mg._MyGrid_Type, oldGdtList
  Protected ret,i,j,ttlW,ttlH,xx,yy
  
  If Not IsWindow(WinNbr) : ProcedureReturn : EndIf
  
  *mg._MyGrid_Type = AllocateMemory(SizeOf(_MyGrid_Type))
  InitializeStructure(*mg, _MyGrid_Type)
  
  W = W - #MyGrid_Scroll_Width
  H = H - #MyGrid_Scroll_Width
  With *mg
    \Window              = WinNbr
    \GadgetX             = X
    \GadgetY             = Y
    \GadgetW             = W
    \GadgetH             = H
  EndWith
  
  ; -- sub-gadgets creation
  oldGdtList = UseGadgetList(WindowID(WinNbr)) 
  ret = CanvasGadget(Gadget, X, Y, W, H, #PB_Canvas_Keyboard);|#PB_Canvas_Border)
  If Gadget = #PB_Any : Gadget = ret: EndIf
  SetGadgetData(Gadget, *mg)
  *mg\Gadget = Gadget
  BindEvent(#PB_Event_SizeWindow, @_MyGrid_Resize(), WinNbr, Gadget)
  
  If NoScrollBars
    *mg\ColScroll = -1
    *mg\RowScroll = -1
  Else
    *mg\ColScroll = ScrollBarGadget(#PB_Any,0,0,0,0,0,0,0)
    SetGadgetData(*mg\ColScroll, *mg)
    BindGadgetEvent(*mg\ColScroll, @_MyGrid_SynchronizeGridCols(), #PB_All)
    
    *mg\RowScroll = ScrollBarGadget(#PB_Any,0,0,0,0,0,0,0, #PB_ScrollBar_Vertical)
    SetGadgetData(*mg\RowScroll, *mg)
    BindGadgetEvent(*mg\RowScroll, @_MyGrid_SynchronizeGridRows(), #PB_All)
  EndIf
  *mg\TxtEdit = StringGadget(#PB_Any,0,0,0,0,"",#PB_String_BorderLess)
  *mg\CmbEdit = ListViewGadget(#PB_Any,0,0,0,0)
  
  UseGadgetList(oldGdtList)
  
  _MyGrid_Reset(*mg, Rows, Cols)
  
  ; no drawing - useful if we need to customize the grid first
  If DoNotDraw = #False
    _MyGrid_Draw(*mg)
  EndIf
  
  
  ProcedureReturn Gadget
  
EndProcedure
;---------------------------

;--- Test and examples
;{
CompilerIf #PB_Compiler_IsMainFile
  
  Enumeration 
    #Win_Nbr
    #Btn_Nbr
    #Grid_Nbr
    #Grid_PopupMenu
    #MenuItem_1
    #MenuItem_2
    #MenuItem_3
    #MenuItem_4
    #MenuItem_5
  EndEnumeration
  
  Global ii,jj,rr,cc,ss,EvGd, Evnt, EvTp, EvMn, wrd.s
  Global Font_A16    = LoadFont(#PB_Any, "Arial", 16)
  If OpenWindow(#Win_Nbr, 0, 0, 1000, 670, "MyGrid Said", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered|#PB_Window_SizeGadget)
    SetWindowColor(#Win_Nbr,#White)
    
    If CreatePopupMenu(#Grid_PopupMenu)      ; creation of the pop-up menu begins...
      MenuItem(#MenuItem_1, "Show")
      MenuItem(#MenuItem_2, "Hide")
      MenuItem(#MenuItem_3, "Freeze here")
      MenuBar()
      OpenSubMenu("Sub-menu")
      MenuItem(#MenuItem_4, "sub 1")
      MenuItem(#MenuItem_5, "sub 2")
      CloseSubMenu()
    EndIf
    
    rr = 2000 : cc = 100
    MyGrid_New(#Win_Nbr, #Grid_Nbr, 10, 10, 920, 650,rr,cc,#True)
    
    ButtonGadget(#Btn_Nbr, 940, 10, 40,20,"buttton")
    
    ; customize the grid ...
    MyGrid_AttachPopup(#Grid_Nbr, #Grid_PopupMenu)
    MyGrid_NoRedraw(#Grid_Nbr)
    ss = MyGrid_AddNewStyle(#Grid_Nbr, 0, #MyGrid_RC_Any)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, RGB(185, 211, 238))
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Center)
    MyGrid_AssignStyle(#Grid_Nbr, #MyGrid_RC_Any, 0, ss)
    
    ; freezing at cell (5,3)
    MyGrid_Row_Freeze(#Grid_Nbr, 5)
    MyGrid_Col_Freeze(#Grid_Nbr, 3)
    
    ; assing a style for frozen rows/cols
    ss = MyGrid_AddNewStyle(#Grid_Nbr)  ; new style not assigned yet
    MyGrid_LastStyle_BackColor(#Grid_Nbr, $FFFFF0)
    For ii=1 To MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_FrozenRow)
      MyGrid_AssignStyle(#Grid_Nbr, ii, #MyGrid_RC_Data, ss)  ; style applied to whole column
    Next
    For ii=1 To MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_FrozenCol)
      MyGrid_AssignStyle(#Grid_Nbr, #MyGrid_RC_Data, ii, ss)  ; style applied to whole row
    Next
    
    ; example of extra style ( buttons at col# 5)
    ss = MyGrid_AddNewStyle(#Grid_Nbr)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, RGB(207, 207, 207))
    MyGrid_LastStyle_CellType(#Grid_Nbr, #MyGrid_CellType_Button)
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Center)
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    MyGrid_Col_ChangeWidth(#Grid_Nbr,5,90)
    For ii=15 To 25
      MyGrid_SetText(#Grid_Nbr, ii, 5, "Click me"+Str(ii))
      MyGrid_AssignStyle(#Grid_Nbr, ii, 5, ss)  ; style applied to some cells
    Next
    
    ; example of extra style ( editable at col# 6 with 2 different edit modes)
    ; Append-mode needs return/esc to exit; arrow-keys navigate thru text - default
    ss = MyGrid_AddNewStyle(#Grid_Nbr)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, RGB(255, 246, 143))
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Right)
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    For ii=7 To 10
      MyGrid_SetText(#Grid_Nbr, ii, 6, "type ...")
      MyGrid_AssignStyle(#Grid_Nbr, ii, 6, ss)  ; style applied to some cells
    Next
    
    ; edit Over-mode, arrow-keys --> exit cell
    ss = MyGrid_AddNewStyle(#Grid_Nbr)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, RGB(0, 238, 238))
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Left)
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    MyGrid_LastStyle_EditMode(#Grid_Nbr, #MyGrid_Edit_Over)
    For ii=12 To 18
      MyGrid_SetText(#Grid_Nbr, ii, 6, "type ...")
      MyGrid_AssignStyle(#Grid_Nbr, ii, 6, ss)  ; style applied to some cells
    Next
    
    ; example of extra style ( checkboxes at col# 9)
    ss = MyGrid_AddNewStyle(#Grid_Nbr, #MyGrid_RC_Data, 9)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, $F5F5F5)
    MyGrid_LastStyle_CellType(#Grid_Nbr, #MyGrid_CellType_Checkbox)
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Center)
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    
    ; setting row 30 to checkboxes as well: row-style prevails on col-style!
    ;  Cells (30,1) (30,2) (30,3) are now checknoxes! not like other frozen cells
    MyGrid_AssignStyle(#Grid_Nbr, 30, #MyGrid_RC_Data, ss)
    
    ; example of extra style ( comboboxes at col# 11, some rows)
    ss = MyGrid_AddNewStyle(#Grid_Nbr, 21, 11)
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Center)
    MyGrid_LastStyle_BackColor(#Grid_Nbr, RGB(255, 239, 219))
    MyGrid_LastStyle_ForeColor(#Grid_Nbr, RGB(238, 59, 59))
    MyGrid_LastStyle_CellType(#Grid_Nbr, #MyGrid_CellType_Combo)
    MyGrid_LastStyle_Items(#Grid_Nbr, "A"+Chr(10)+"B"+Chr(10)+"C"+Chr(10)+"D"+Chr(10)+"D2"+Chr(10)+"E"+Chr(10)+"F", Chr(10))
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    For rr= 22 To 25
      MyGrid_AssignStyle(#Grid_Nbr, rr, 11, ss)
    Next
    MyGrid_MergeCells(#Grid_Nbr,  23, 11, 24, 11) ; merging two combos together !!
    
    ; span cells, herites style and text of its first cell
    MyGrid_MergeCells(#Grid_Nbr,  7, 12, 8, 14)
    MyGrid_MergeCells(#Grid_Nbr, 10, 12, 16, 14)
    ss = MyGrid_AddNewStyle(#Grid_Nbr)
    MyGrid_LastStyle_Align(#Grid_Nbr, #MyGrid_Align_Center)
    MyGrid_LastStyle_ForeColor(#Grid_Nbr, $3333CD)
    MyGrid_LastStyle_Editable(#Grid_Nbr, #True)
    MyGrid_LastStyle_Font(#Grid_Nbr, Font_A16)
    For cc= 12 To 14
      For rr =6 To 18
        MyGrid_SetText(#Grid_Nbr, rr, cc, "("+rr+","+cc+")")
        MyGrid_AssignStyle(#Grid_Nbr, rr, cc, ss)
      Next
    Next
    MyGrid_Row_AutoHeight(#Grid_Nbr,6) ; big font
    MyGrid_Row_AutoHeight(#Grid_Nbr,18) ; big font
    
    ; hiding col 7 and row 17
    MyGrid_Col_Hide(#Grid_Nbr, 7, 1)
    MyGrid_Row_Hide(#Grid_Nbr,17, 1)
    
    ; <<<--------------- Hiding Focus Rectangle ------------------------>>>
    ; Example: to hide focus-rectangle,. change its color to -1 / ozzie / un-comment below line
    ;MyGrid_SetColorAttribute(#Grid_Nbr, #MyGrid_Color_FocusBorder, -1)
    
    MyGrid_Redraw(#Grid_Nbr)
    
    Repeat
      EvGd = -1
      EvTp = -1
      EvMn = -1
      Evnt = WaitWindowEvent()
      Select Evnt
          
        Case #MyGrid_Event_Change
          EvGd = EventGadget()
          If EvGd = #Grid_Nbr
            rr = MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_ChangedRow)
            cc = MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_ChangedCol)
            wrd = MyGrid_LastChangedCellText(#Grid_Nbr)
            Debug " ... Change occured in Cell (" + Str(rr) +","+ Str(cc) + ") .. old text:" + wrd 
          EndIf
          
        Case #MyGrid_Event_Click
          EvGd = EventGadget()
          If EvGd = #Grid_Nbr
            rr = MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_ClickedRow)
            cc = MyGrid_GetAttribute(#Grid_Nbr, #MyGrid_Att_ClickedCol)
            Debug " ... Button clicked in Cell (" + Str(rr) +","+ Str(cc) + ")"
          EndIf
          
        Case #PB_Event_SizeWindow
          MyGrid_Resize(#Grid_Nbr, #PB_Ignore, #PB_Ignore, WindowWidth(#Win_Nbr) - 80, WindowHeight(#Win_Nbr) - 20)
          
        Case #PB_Event_Gadget 
          EvGd = EventGadget()
          EvTp = EventType()
          Select EvGd
            Case #Btn_Nbr
              Debug " button clicked ... "
            Case #Grid_Nbr
              MyGrid_ManageEvent(EvGd, EvTp)
          EndSelect
          
        Case #PB_Event_Gadget 
          
        Case #PB_Event_Menu
          EvMn = EventMenu()
          Select EvMn
            Case #MenuItem_1 : Debug " popup menu 1 "
            Case #MenuItem_2 : Debug " popup menu 2 "
            Case #MenuItem_3 : Debug " popup menu 3 "
            Case #MenuItem_4 : Debug " popup menu 4 "
            Case #MenuItem_5 : Debug " popup menu 5 "
          EndSelect
          
      EndSelect
      
      
    Until  Evnt = #PB_Event_CloseWindow
  EndIf
CompilerEndIf
;}

