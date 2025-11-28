/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer     | 11/10/2017 | Acerto da ordem do SF2 para nota de Remessa - Chamado 21974 
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 26/10/2018 | Inclusão rotinas de transmissão e monitor por carga - Chamado 26701
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer     | 14/03/2022 | Nova validação da NF de remessa  - Chamado 39457
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FISVALNFE()
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 21/08/2017 
===============================================================================================================================
Descrição---------: Ponto de entrada na transmissão do SPED apos selecionar as notas
===============================================================================================================================
Parametros--------: Recebe aValNFe Posições:
		aAdd(aValNFe,If((cAliasSF3)->F3_CFO < "5","E","S"))// 1
		aAdd(aValNFe,(cAliasSF3)->F3_FILIAL)  // 2
		aAdd(aValNFe,(cAliasSF3)->F3_ENTRADA) // 3
		aAdd(aValNFe,(cAliasSF3)->F3_NFISCAL) // 4
		aAdd(aValNFe,(cAliasSF3)->F3_SERIE)   // 5
		aAdd(aValNFe,(cAliasSF3)->F3_CLIEFOR) // 6
		aAdd(aValNFe,(cAliasSF3)->F3_LOJA)    // 7
		aAdd(aValNFe,(cAliasSF3)->F3_ESPECIE) // 8
		aAdd(aValNFe,(cAliasSF3)->F3_FORMUL)  // 9
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FISVALNFE()

Local aValNFe:= ParamIXB
Local _lRet  := .T.
Local _cChave:= aValNFe[2]+aValNFe[4]+aValNFe[5]+aValNFe[6]+aValNFe[7]//aValNFe[2]+SC9->C9_NFISCAL+SC9->C9_SERIENF+SC9->C9_CLIENTE+SC9->C9_LOJA)
Local _aSC5	 := GetArea("SC5")
Local _aSF2	 := GetArea("SF2")

Begin Sequence

   SF2->(DBSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
   If !SF2->(MsSeek(_cChave))
      BREAK
   EndIf
   
   //Se passou por filtro de carga faz a conferência se está selecionada a nota
   If Select ("IT_TRB") > 0
	
		DBSelectArea("IT_TRB")
		IT_TRB->( DBSetOrder(1) )
			
		IT_TRB->(MsSeek( AllTrim(SF2->F2_DOC)  , .T. ))
		
		If !(AllTrim(IT_TRB->TRBF_DOC) == AllTrim(SF2->F2_DOC) .And. IsMark( "TRBF_OK" , _cMarkado ))
		
		  _lRet := .F.
		  BREAK
		
		EndIf 
	
   EndIf
   

   SC5->(DBSetOrder(1))
   If !SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID)) 
      BREAK
   EndIf

   If !SC5->C5_I_OPTRI $ "F,R" 
      BREAK
   EndIf

   _nRecSC5:= SC5->(RECNO())
   _nRecSF2:= SF2->(RECNO())
   _cPedRemessa := SC5->C5_I_PVREM
   _cPedFaturam := SC5->C5_I_PVFAT
   _cProblema   := _cSolucao := ""
   SF2->(DBORDERNICKNAME("IT_I_PEDID"))

//  *****************     NOTA FICAL DE VENDA  ********************
   If SC5->C5_I_OPTRI = "F" // Estou no PV de Faturamento e vou buscar o de Remessa
      If !SC5->(DBSeek(xFilial()+_cPedRemessa)) .Or. !SF2->(DBSeek(xFilial()+_cPedRemessa))
         _cProblema:="Nota Fiscal do Pedido de Remessa : "+_cPedRemessa+" nao gerada."
         _cSolucao :="Transmitir essa Nota de Venda: "+aValNFe[4]+" somente apos gerar a nota do Pedido de Remessa."
         _lRet:= .F.
      EndIf
//  *****************     NOTA FICAL DE REMESSA 42 ********************
   ElseIf SC5->C5_I_OPTRI = "R" // ... SE O TIPO ATUAL For O PV DE REMESSA BUSCA A NF DE FATURAMENTO

     SA1->(DBSetOrder(1))
     If SA1->( DBSeek( xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI ) ) .And. SA1->A1_I_OBRAD = "S"
        If Empty(SF2->F2_I_NTRIA)  //SF2 JÁ ESTA POSICIONADO NA LINHA 55
           _cProblema:="Nota Fiscal do Pedido de Remessa : "+_cPedRemessa+" nao possui os dados do adquirente."
           _cSolucao :="Transmitir essa Nota de Remessa (Oper.42) : "+aValNFe[4]+" somente apos colocar os dados do adquirente."
           _lRet:= .F.
        EndIf     
        If SF2->(DBSeek(xFilial()+_cPedFaturam)) .And. Empty(SF2->F2_CHVNFE)
           _cProblema:="Nota Fiscal de Venda (Oper.05) não transmitida para o Pedido : "+_cPedFaturam+" e Nfe : "+SF2->(F2_DOC+" "+F2_SERIE )
           _cSolucao :="Transmissão da Nota de Remessa (Oper.42) somente apos a Transmissão da Nota fiscal de Vendas (Oper.05)."
           _lRet:= .F.
        EndIf
     EndIf
      
     If !SC5->(DBSeek(xFilial()+_cPedFaturam)) .Or. !SF2->(DBSeek(xFilial()+_cPedFaturam))
         _cProblema:="Nota Fiscal de Venda (Oper.05) não gerada para o do Pedido : "+_cPedFaturam+"."
         _cSolucao :="Transmissão da Nota de Remessa (Oper.42) somente apos a Transmissão da Nota fiscal de Vendas (Oper.05)."
         _lRet:= .F.
     EndIf


   EndIf

   If _lRet
      If Empty(SF2->F2_I_MENOT)
         _cProblema:="Campo de mensagem da Operacao Triangular não preenchido, Nota: "+aValNFe[4]+" Pedido: "+AllTrim(_cPedRemessa+_cPedFaturam)//Sempre um outro vai estar preenchido senão é que deu xabu
         _cSolucao :="Entrar em contato com a area de TI com printe dessa mensagem."
         _lRet  := .F.
      EndIf
   EndIf
   If !Empty(_cProblema)
      U_ITMsg(_cProblema,"ATENÇÃO",_cSolucao,1)
   EndIf

End Sequence

FWRestArea(_aSC5) 
FWRestArea(_aSF2) 

Return _lRet
