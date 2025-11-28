/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |29/10/2021| Chamado 38037. Inclusão do campo F1_I_FUNDF para preenchimento na inclusão e classificação.
Igor Melgaço  |18/11/2021| Chamado 38289. Colocado como inicialização padrão Nao o campo F1_I_FUNDF na inclusão e classificação.
Julio Paz     |15/08/2025| Chamado 51822. Ajustar as opções customizadas de tela para serem exibidas corretamente no Tema Dark. 
===============================================================================================================================
 Analista      - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração                                                                                 
=====================================================================================================================================================================================================
André          - Julio Paz    - 11/11/25 - 24/11/25 - 52393   - Inclusão da Opção Armazém na Funcionalidade Replicar Dados para as Linhas na Tela de Lançamento de Nota Fiscal de Entrada.
=====================================================================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA103BUT
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/09/2019
Descrição---------: Ponto de entrada da criação de botões do menu da tela de classificação de notas fiscais de entradas.
                    Chamado 29762 e 30834. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA103BUT

Local aButtons := {}
Local aArea := FWGetArea()
Local lEdit
Local nAba
Local oCbxFUNDFIX
Local _aBoxFUNDF := RetSX3Box(GetSX3Cache("F1_I_FUNDF", "X3_CBOX"),,,1)
Local _cIPFUNDF  := ""
Local _aCombo    := {}
Local _nI        := 0
Public _cFUNDFIX := ""

Begin Sequence
   
   aAdd(aButtons, {"Replica Tp.Op." , {|| U_A103TpOp() } , "Replica Dados para as Linhas"})

End Sequence
 
//Adiciona uma nova aba no documento de entrada
oFolder:AddItem("Italac", .T.)
nAba := Len(oFolder:aDialogs)

For _nI := 1 To Len(_aBoxFUNDF)
    aAdd(_aCombo,_aBoxFUNDF[_nI][3])
Next

If INCLUI
    _cFUNDFIX := CriaVar("F1_I_FUNDF",.F.)
    _cIPFUNDF := GetSX3Cache("F1_I_FUNDF","X3_RELACAO") 
    _cIPFUNDF := IIf(Empty(AllTrim(_cIPFUNDF))," ",&(AllTrim(_cIPFUNDF)))
    _cFUNDFIX := U_ITRetBox( _cIPFUNDF , "F1_I_FUNDF" )

    lEdit := .T.
Else
    _cFUNDFIX := U_ITRetBox( SF1->F1_I_FUNDF , "F1_I_FUNDF" )

    If Empty(AllTrim(_cFUNDFIX))
        _cIPFUNDF := GetSX3Cache("F1_I_FUNDF","X3_RELACAO") 
        _cIPFUNDF := IIf(Empty(AllTrim(_cIPFUNDF))," ",&(AllTrim(_cIPFUNDF)))
        _cFUNDFIX := U_ITRetBox( _cIPFUNDF , "F1_I_FUNDF" )
    EndIf

    lEdit := .F.
EndIf

//Criando na janela o campo 
@ 005, 003 Say AllTrim(RetTitle("F1_I_FUNDF")) OF oFolder:aDialogs[nAba] PIXEL SIZE 050,006
@ 003, 053 COMBOBOX oCbxFUNDFIX VAR _cFUNDFIX ITEMS _aCombo SIZE 030, 006 OF oFolder:aDialogs[nAba] PIXEL 
oCbxFUNDFIX:bHelp := {|| ShowHelpCpo( "F1_I_FUNDF", {GetHlpSoluc("F1_I_FUNDF")[1]}, 5  )}

//Se não houver edição, desabilita os gets
If ! lEdit
    If Type("_lClassif") != "U"
        oCbxFUNDFIX:lActive := .T.
    Else
        oCbxFUNDFIX:lActive := .F.
    EndIf
EndIf

FWRestArea(aArea)

Return (aButtons)

/*
===============================================================================================================================
Programa----------: A103TpOp
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2019
Descrição---------: Replica o tipo de operação para os itens da nota fiscal.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A103TpOp

Local _bOk, _bCancel
Local _lRet := .F.
Local _nLinha := N 
Local _nPosOper , T
Local _cValidOper := Getsx3cache("D1_OPER","X3_VALID")
Local _nPosProd
Local _nPosCC
Local _cValidCC  := Getsx3cache("D1_CC","X3_VALID")
Local _cValidLoc := Getsx3cache("D1_LOCAL","X3_VALID")
Local _cUsrVlLoc := Getsx3cache("D1_LOCAL","X3_VLDUSER")
Local _nLin 
Local _nPosLocal := 0

Private _cTipoOper := Space(2)
Private _cCodCC    := Space(9)                             
Private _cLocal    := Space(2)

Begin Sequence
 
   _bOk := {|| _lRet := .T., _oDlgTPOp:End()}
   _bCancel := {|| _lRet := .F., _oDlgTPOp:End()}
                       
   _cTitulo := "Replica Dados Para os Itens da Nota Fiscal de Entrada"
   
   Define MsDialog _oDlgTPOp Title _cTitulo From 0,0 To 15, 80 Of oMainWnd 

      _nLin := 30
      @ _nLin,010 Say "Tipo de Operação:"	SIZE 065,010 PIXEL OF _oDlgTPOp // 040
      @ _nLin,060 MSGET _cTipoOper PICTURE "@!" F3 "DJ" Valid(Vazio() .Or. ExistCpo("SX5","DJ" + _cTipoOper)) SIZE 40,010 PIXEL OF _oDlgTPOp 
      
      _nLin += 15
      @ _nLin,010 Say "Centro de Custo:"	SIZE 065,010 PIXEL OF _oDlgTPOp 
      @ _nLin,060 MSGET _cCodCC PICTURE "@!" F3 "CTT" Valid(Vazio() .Or. ExistCpo("CTT",_cCodCC)) SIZE 40,010 PIXEL OF _oDlgTPOp

      _nLin += 15
      @ _nLin,010 Say "Armazém:"	SIZE 065,010 PIXEL OF _oDlgTPOp 
      @ _nLin,060 MSGET _cLocal PICTURE "@!" F3 "NNR" Valid(Vazio() .Or. ExistCpo("NNR",_cLocal)) SIZE 40,010 PIXEL OF _oDlgTPOp
                                                                           
   Activate MsDialog _oDlgTPOp On Init EnchoiceBar(_oDlgTPOp,_bOk,_bCancel) CENTERED 

   If _lRet
      _nPosOper  := aScan(aHeader,{|x| AllTrim(x[2]) == "D1_OPER"})
      _nPosProd  := aScan(aHeader,{|x| AllTrim(x[2]) == "D1_COD"})      
      _nPosCC    := aScan(aHeader,{|x| AllTrim(x[2]) == "D1_CC"})
      _nPosLocal := aScan(aHeader,{|x| AllTrim(x[2]) == "D1_LOCAL"})
                                  
      If ! Empty(_cTipoOper)     
         __ReadVar := 'M->D1_OPER'
      
         For T := 1 To Len(aCols)
             N := T
             M->D1_OPER := _cTipoOper
             aCols[N,_nPosOper] := _cTipoOper
         
             If ! &(_cValidOper)
                U_ITMsg("Tipo de operação informado inexistente [" + aCols[N,_nPosOper] + "], para o Produto ["+AllTrim(aCols[N,_nPosProd])+"], linha: " + StrZero(N,3) + "." ,"Atenção", ,1)
                Exit
             EndIf

             If ExistTrigger("D1_OPER   ")  
                RunTrigger(2,T,,,"D1_OPER   ")  
             EndIf            
         Next 
      EndIf                  
      
      If ! Empty(_cCodCC)
         __ReadVar := 'M->D1_CC'
      
         For T := 1 To Len(aCols)
             N := T
             M->D1_CC := _cCodCC
             aCols[N,_nPosCC] := _cCodCC
         
             If ! &(_cValidCC)
                U_ITMsg("O Centro de Custo informado inexistente [" + aCols[N,_nPosCC] + "], para o Produto ["+AllTrim(aCols[N,_nPosProd])+"], linha: " + StrZero(N,3) + "." ,"Atenção", ,1)
                Exit
             EndIf

             If ExistTrigger("D1_CC     ")  
                RunTrigger(2,T,,,"D1_CC     ")  
             EndIf            
         Next
      EndIf
   
      If ! Empty(_cLocal)
         __ReadVar := 'M->D1_LOCAL'
      
         For T := 1 To Len(aCols)
             N := T
             M->D1_LOCAL := _cLocal
             aCols[N,_nPosLocal] := _cLocal
         
             If ! &(_cValidLoc)
                U_ITMsg("O Armazém informado inexistente [" + aCols[N,_nPosLocal] + "], para o Produto ["+AllTrim(aCols[N,_nPosProd])+"], linha: " + StrZero(N,3) + "." ,"Atenção", ,1)
                Exit
             EndIf

             If ! &(_cUsrVlLoc)
                U_ITMsg("O Armazém informado não é valido [" + aCols[N,_nPosLocal] + "], para o Produto ["+AllTrim(aCols[N,_nPosProd])+"], linha: " + StrZero(N,3) + "." ,"Atenção", ,1)
                Exit
             EndIf

             If ExistTrigger("D1_LOCAL  ")  
                RunTrigger(2,T,,,"D1_LOCAL  ")  
             EndIf            
         Next
      EndIf
   EndIf

End Sequence

N := _nLinha

Return
