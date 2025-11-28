/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |05/01/2017| Chamado 18252 Ajustar os saldos para considerar somente 3 casas decimais
Lucas Borges  |22/02/2017| Chamado 18959 Incluída regra para realizar validações apenas se produto movimentar Seg UM
Alex Walaluer |20/01/2025| Chamado 49616. Ajuste para pegar as decimais do campo D7_SALDO
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT175FOK()
Autor-------------: Andre Lisboa
Data da Criacao---: 05/12/2016  
Descrição---------: Liberacao / Rejeicao do Material no CQ por linha.
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MT175FOK() as Logical

 Local _lRet    := .T. As Logical
 Local _nSaldo  := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_SALDO"  })] As Numeric
 Local _nSaldo2 := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_SALDO2" })] As Numeric
 Local _nQtsegum:= Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_QTSEGUM"})] As Numeric
 Local _cEstorn := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_ESTORNO"})] As Character
 Local _cTipo   := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_TIPO"   })] As Character
 Local _cMotRej := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_MOTREJE"})] As Character
 Local _nNumseq := Acols[N][aScan(aHeader, {|x| AllTrim(x[2]) == "D7_NUMSEQ" })] As Numeric
 Local _nDec    := GetSX3Cache("D7_SALDO","X3_DECIMAL") As Numeric
 
 If !Empty(SB1->B1_SEGUM)
     If Round(_nSaldo2,_nDec) > 0 .And. _nQtsegum = 0 .And. Empty(_cEstorn) .And. _cTipo <> 0
         _lRet := .F.                                                                                       	
         xMagHelpFis("Atenção!", "Não permitido! A quantidade informada na 2a.UM é zero.",;
                                "Favor informar a quantidade da 2a.UM.")
     EndIf
     
     If Round(_nsaldo,_nDec) = 0 .And. Round(_nSaldo2,_nDec) <> 0
         _lRet := .F.                                                                                       	
         xMagHelpFis("Atenção!", "Não permitido! O saldo da quantidade da 2a.UM não zerou.",;
                                "Favor informar a quantidade da 2a.UM.")
     
     ElseIf Round(_nSaldo,_nDec) <> 0 .And. Round(_nSaldo2,_nDec) = 0
         _lRet := .F.                                                                                       	
         xMagHelpFis("Atenção!", "Não permitido! O saldo da quantidade da 2a.UM zerou, porém ainda existe saldo da 1a.UM.",;
                                "Favor verificar os lançamentos (Liberações e rejeições).")
     EndIf
 EndIf
 
 If _cTipo == 2 .And. Empty(_cMotRej) .And. Empty(_nNumseq)
     _lRet := .F. 
     xMagHelpFis("Atenção!", "Não permitido! Quando o produto For REJEITADO é obrigatório o preenchimento do motivo da rejeição",;
                                "Favor verificar o conteúdo do campo 'Motivo da Rejeição'.")	
 EndIf

Return _lRet
