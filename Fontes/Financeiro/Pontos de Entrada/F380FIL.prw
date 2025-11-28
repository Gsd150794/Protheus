/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Jonathan      |29/04/2020| Chamado 32436. Corrigido mensagem de help sobre a sintaxe SQL utilizada no ponto de entrada.
Alex Wallauer |05/10/2020| Chamado 34305. Corrigido a validacao do "Tipo Movimentação?"
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F380FIL
Autor-------------: Frederico O. C. Jr 
Data da Criacao---: 05/03/2008
Descrição---------: Ponto de Entrada com o objetivo de criar filtros na conciliacao bancaria	
Parametros--------: Nenhum
Retorno-----------: cFiltro = instrucao do filtro a ser realizado  
===============================================================================================================================
*/
User Function F380FIL(cFiltro)

	Local aArea     := FWGetArea()
    Local cCheq1    := Space(9)
    Local cCheq2    := "ZZZZZZZZZ"
    Local nVal1     := 0
    Local nVal2     := 999999999.99
    Local oDlg1     := NIL
    Local oGrp1     := NIL
    Local oTipoMov  := NIL
 
    _cTipoMov := "Ambos"
    DEFINE MSDIALOG oDlg1 TITLE "Conciliação Bancaria" FROM 112,245 TO 320,770 PIXEL
 
        oGrp1   := TGroup():New( 012,012,100,248,"Filtro",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )
            @ 028,016   Say "Do Cheque:"    of oGrp1            PIXEL
            @ 024,052   MSGET cCheq1    size 060,008 of oGrp1   PIXEL
            @ 028,132   Say "Ate Cheque:"   of oGrp1            PIXEL
            @ 024,168   MSGET cCheq2    size 060,008 of oGrp1   PIXEL
            @ 048,016   Say "Do Valor:"     of oGrp1 PIXEL
            @ 044,052   MSGET nVal1     size 060,008 picture '@E 999,999,999.99'    of oGrp1 PIXEL
            @ 048,132   Say "Ate Valor:"    of oGrp1 PIXEL
            @ 044,168   MSGET nVal2     size 060,008 picture '@E 999,999,999.99'    of oGrp1 PIXEL
             
            @ 66, 016 Say "Tipo Movimentação?"  Pixel Size 050,006 Of oGrp1
            @ 64, 075 MSCOMBOBOX oTipoMov Var _cTipoMov ITEMS {"Ambos","Receber","Pagar"} Valid (Pertence("Ambos,Receber,Pagar")) Pixel Size 070, 012 Of oGrp1
             
        DEFINE SBUTTON FROM 086,115 Type 1 ACTION (oDlg1:End()) ENABLE OF oDlg1 // 085,115
 
    Activate Dialog oDlg1 Center
     
    cFiltro := "(E5_NUMCHEQ >= '"+ cCheq1 +"' AND E5_NUMCHEQ <= '"+ cCheq2 +"') AND " +;
                "(E5_VALOR >= "+ Str(nVal1) +" AND E5_VALOR <="+ Str(nVal2) +") "
                 
    If AllTrim(_cTipoMov) == "Receber"
       cFiltro += " AND E5_RECPAG = 'R' "
    EndIf
     
    If AllTrim(_cTipoMov) == "Pagar"
       cFiltro += " AND E5_RECPAG = 'P' "
    EndIf
 
    FWRestArea(aArea)
         
Return cFiltro
