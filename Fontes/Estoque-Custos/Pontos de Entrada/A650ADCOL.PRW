/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |05/09/2019| Chamado 27300. Ajustes na gravação dos campos D4_I_QTORI e D4_I_QORSG.
Alex Wallauer |20/07/2022| Chamado 40378. Ajustes na gravação do campo D4_LOCAL.
===============================================================================================================================
*/

#Include "TOTVS.ch"
                     
/*
===============================================================================================================================
Programa----------: A650ADCOL
Autor-------------: Alex Wallauer
Data da Criacao---: 03/01/2019
Descrição---------: PE para atualizar o aCols da tela de Empenho - Chamado 27300
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/ 
User Function A650ADCOL(_lGatilho)

Local nPos1     :=aScan(aHeader,{|x| AllTrim(x[2])=="B2_QATU"})
Local nPosLocal :=aScan(aHeader,{|x| AllTrim(x[2])=="D4_LOCAL"})
Local nPosCod   :=aScan(aHeader,{|x| AllTrim(x[2])=="G1_COMP"})
Local nPospQUANT:=aScan(aheader,{|x| AllTrim(x[2])=="D4_QUANT"})
Local nPospQTSEG:=aScan(aheader,{|x| AllTrim(x[2])=="D4_QTSEGUM"})
Local nPospQTORI:=aScan(aheader,{|x| AllTrim(x[2])=="D4_I_QTORI"})
Local nPospQORSG:=aScan(aheader,{|x| AllTrim(x[2])=="D4_I_QORSG"})
Local cCodPrd
Local cRetLocal
Local cTipo
Local cArmz
Local cArmPulm

DEFAULT _lGatilho := .F.

If _lGatilho//Quando chamado do PE MTA650AC.PRW
   M->D4_LOCAL:=M->D4_LOCAL
   SB2->(DBSetOrder(1))
   If SB2->(DBSeek(xFilial()+aCols[N,nPosCod]+M->D4_LOCAL))
	  aCols[N,nPos1] := SaldoSB2()
   EndIf
Else
   cCodPrd  :=  aCols[Len(aCols),nPosCod]	//Código do Produto
   cRetLocal:=  aCols[Len(aCols),nPosLocal]	//Armazém padrão
   cTipo	:=  Posicione("SB1",1,xFilial("SB1")+cCodPrd,"B1_TIPO") //Tipo do Produto
   cArmz	:= GetMv("IT_ARMEMP")       //Armazéns para troca automática na geração do empenho
   cArmPulm	:= GetMv("IT_ARMPULM") 		//Armazém pulmão da fábrica
   If cTipo<>'MP' .And. cRetLocal $ cArmz		//('00/02/20/') //Verifca se o produto não é 'MP' e o Armazém é '02' altera conteúdo para '04'
      If SuperGetMv( "MV_RASTRO"  , .F. , ""  ) ="S"
         cRetLocal := MV_PAR03
      Else
         cRetLocal := cArmPulm
      EndIf
   EndIf
   //Se filial é 90, altera empenhos para armazem 35. Chamado 7225
   If xFilial("SC5") == "90" 
      cRetLocal := "35"
   EndIf
   aCols[Len(aCols),nPosLocal]  := cRetLocal
   aCols[Len(aCols),nPospQTORI] := aCols[Len(aCols),nPospQUANT]
   aCols[Len(aCols),nPospQORSG] := aCols[Len(aCols),nPospQTSEG]

   SB2->(DBSetOrder(1))
   If SB2->(DBSeek(xFilial()+aCols[Len(aCols),nPosCod]+aCols[Len(aCols),nPosLocal]))
	  aCols[Len(aCols),nPos1] := SaldoSB2()
   EndIf
EndIf
Return .T.
