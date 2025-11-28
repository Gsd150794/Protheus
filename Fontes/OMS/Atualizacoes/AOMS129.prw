/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor     |    Data    |                                             Motivo                                           
------------------------------------------------------------------------------------------------------------------------------- 
                 |            |
=============================================================================================================================== 
*/

//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'
  
/*
===============================================================================================================================
Programa----------: AOMS129()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/07/2021
===============================================================================================================================
Descrição---------: Rotina de visualização dos dados do Operador logistico e Operador de Redespacho vinculos a nota fical.
===============================================================================================================================
Parametros--------: _cTitulo   = Titulo da tela.
                    _cCod      = Codigo do fornecedor.
                    _cLoja     = Loja do fornecedor.
                    _cTipoCons = Tipo de consulta 
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS129(_cTitulo,_cCod,_cLoja,_cTipoCons)
Local _oDlgCons
Local _bOk, _bCancel 
Local _cMsg, _nLin, _nCol1, _nCol2 
Local _nCol3, _nCol4
Local _cEndereco, _cTelefone

Begin Sequence

   SA2->(DBSetOrder(1)) 
   
   If _cTipoCons == "LOGISTICO"
      _cMsg := "Operador Logístico: " + _cCod + "/" + _cLoja + ", não localizado no cadastro de fornecedores."
   ElseIf _cTipoCons == "REDESPACHO"
      _cMsg := "Operador de Redespacho: " + _cCod + "/" + _cLoja + ", não localizado no cadastro de fornecedores."
   Else 
      _cMsg := ""
   EndIf 
   
   If ! SA2->(MsSeek(xFilial("SA2")+_cCod+_cLoja))
      U_ITMsg(_cMsg,"Atenção",,1)
      Break 
   EndIf 
   
   _bOk := {|| _oDlgCons:End()}
   _bCancel := {|| _oDlgCons:End()}

    _nLin  := 40
    _nCol1 := 20
    _nCol2 := 60
    _nCol3 := 180
    _nCol4 := 200
   
   Define MsDialog _oDlgCons Title _cTitulo From 9,0 To 35,120 Of oMainWnd 
      
      @ _nLin,_nCol1 Say "Código: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_COD Size 50, 10 WHEN .F. Of _oDlgCons Pixel

      @ _nLin,_nCol3 Say "Loja: " Of _oDlgCons Pixel 
      @ _nLin,_nCol4 Get SA2->A2_LOJA Size 50, 10 WHEN .F. Of _oDlgCons Pixel
      
      _nLin += 15

      @ _nLin,_nCol1 Say "Razão Social: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_NOME Size 200, 10 WHEN .F. Of _oDlgCons Pixel

      _nLin += 15

      @ _nLin,_nCol1 Say "Nome Fantasia: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_NREDUZ Size 150, 10 WHEN .F. Of _oDlgCons Pixel

      _nLin += 15
      _cEndereco := AllTrim(SA2->A2_END)+" "+AllTrim(SA2->A2_NR_END)

      @ _nLin,_nCol1 Say "Endereço: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get _cEndereco Size 120, 10 WHEN .F. Of _oDlgCons Pixel

      _nLin += 15

      @ _nLin,_nCol1 Say "CEP: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_CEP Size 30, 10 PICTURE "@R 99999-999" WHEN .F. Of _oDlgCons Pixel
      
      _nLin += 15

      @ _nLin,_nCol1 Say "Cidade: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_MUN Size 100, 10 WHEN .F. Of _oDlgCons Pixel

      @ _nLin,_nCol3 Say "Estado: " Of _oDlgCons Pixel 
      @ _nLin,_nCol4 Get SA2->A2_EST Size 30, 10 WHEN .F. Of _oDlgCons Pixel
      
      _nLin += 15
      _cTelefone := "("+AllTrim(SA2->A2_DDD)+") " + Transform(SA2->A2_TEL,"@R 9999-99999")

      @ _nLin,_nCol1 Say "Telefone: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get _cTelefone Size 100, 10 WHEN .F. Of _oDlgCons Pixel
      
      _nLin += 15

      @ _nLin,_nCol1 Say "E-mail: " Of _oDlgCons Pixel 
      @ _nLin,_nCol2 Get SA2->A2_EMAIL   Size 350, 10 WHEN .F. Of _oDlgCons Pixel

   Activate MsDialog _oDlgCons On Init EnchoiceBar(_oDlgCons,_bOk,_bCancel) CENTERED 

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS129L()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/07/2021
===============================================================================================================================
Descrição---------: Rotina de visualização dos dados do Operador logistico vinculo a nota fical.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS129L()
Local _cTitulo

Begin Sequence

   If Empty(SF2->F2_I_OPER) .Or. Empty(SF2->F2_I_OPLO)
       U_ITMsg("Não existe Operador Logistico para a nota fiscal: "+ SF2->F2_DOC + "-" + SF2->F2_SERIE + ", da filial: " + SF2->F2_FILIAL + ".","Atenção",,1)
       Break 
   EndIf 
   
   _cTitulo := "Visualização dos Dados do Operador de Logístico"
   
   U_AOMS129(_cTitulo,SF2->F2_I_OPER,SF2->F2_I_OPLO,"LOGISTICO")

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS129R()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/07/2021
===============================================================================================================================
Descrição---------: Rotina de visualização dos dados do Operador de Redespacho vinculo a nota fical.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS129R()
Local _cTitulo

Begin Sequence

   If Empty(SF2->F2_I_REDP) .Or. Empty(SF2->F2_I_RELO)
       U_ITMsg("Não existe Operador de redespacho para a nota fiscal: " + SF2->F2_DOC + "-" + SF2->F2_SERIE + ", da filial: " + SF2->F2_FILIAL + ".","Atenção",,1)
       Break 
   EndIf 
   
   _cTitulo := "Visualização dos Dados do Operador de Redespacho"
   
   U_AOMS129(_cTitulo,SF2->F2_I_REDP,SF2->F2_I_RELO,"REDESPACHO")

End Sequence

Return





