/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FA070CA4
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/03/2011
Descrição---------: Ponto de Entrada no cancelamento do bordero.
Parametros--------: O ponto de entrada FA070CA4 sera executado apos confirmacao do cancelamento da baixa do contas a receber,
					para diante disso efetuar o cancelamento do debito gerado na comissao da baixa.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FA070CA4

Local _lRet     := .T.  
Local _cNumero  := SE1->E1_NUM
Local _cSerie   := IIf(SE1->E1_PREFIXO <> 'MAN',SE1->E1_PREFIXO,Space(3)) 
Local _cParcela := SE1->E1_PARCELA
Local _cTipo    := SE1->E1_TIPO
Local _cCliente := SE1->E1_CLIENTE
Local _cLoja    := SE1->E1_LOJA
Local _cSeq     := SE5->E5_SEQ  
Local _cMotBaixa:= SE5->E5_MOTBX   
    
Local _cAlias  := ""
Local _cFiltro := "%"
Local _aMes    :={"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local  _aArea 	:= FWGetArea()
Local  _aAreaSE1 := SE1->(FWGetArea())
Local  _aAreaSE5 := SE5->(FWGetArea())
Local  _aAreaSE3 := SE3->(FWGetArea())
Local  _aAreaSEF := SEF->(FWGetArea())

//Verifica se o motivo da baixa foi igual a NOR, pois diante disso
//os titulos com baixa igual a NOR passaram por uma avaliacao
//para constatar se a comissao ja foi fechada.
If _cMotBaixa == 'NOR' 

	_cAlias:= GetNextAlias() 
		    
	_cFiltro += " AND E3_FILIAL = '"  + xFilial("SE3") + "'"
	_cFiltro += " AND E3_NUM = '"     + _cNumero       + "'"
	_cFiltro += " AND E3_SERIE = '"   + _cSerie        + "'"
	_cFiltro += " AND E3_PARCELA = '" + _cParcela      + "'"
	_cFiltro += " AND E3_TIPO = '"    + _cTipo         + "'"
	_cFiltro += " AND E3_CODCLI = '"  + _cCliente      + "'"
	_cFiltro += " AND E3_LOJA = '"    + _cLoja         + "'"
	_cFiltro += " AND E3_SEQ = '"     + _cSeq          + "'"
	_cFiltro += " AND E3_I_FECH = 'S'"
	_cFiltro += " AND E3_I_ORIGE <> 'MT100AGR'" //Esta clausula foi solicitada a sua inclusao por Tiago Correa no dia 13/06/11
	_cFiltro += "%"
	
	//Verifica se a comissao encontra-se com o status fechada
	BeginSql alias _cAlias	
		SELECT
	      E3_EMISSAO
		FROM
		      %Table:SE3%
		WHERE
		      D_E_L_E_T_ = ' '
		      %exp:_cFiltro%				
	EndSql   
	
	DBSelectArea(_cAlias)
	(_cAlias)->(DBGoTop())
	              	
	//A baixa que esta sendo feito o cancelamento ou exclusao nao
	//podera ser excluida pois a baixa encontra-se com a comissao fechada.
	If (_cAlias)->(!Eof())
	
		_lRet:= .F.	  
		
		xMagHelpFis("INFORMAÇÃO",;
		            "Não poderá ser realizado o cancelamento ou exclusão da baixa do título! Pois: Essa baixa gerou comissão no mês de " +;
		             _aMes[Val(SubStr((_cAlias)->E3_EMISSAO,5,2))] + " de " + SubStr((_cAlias)->E3_EMISSAO,1,4)+ " onde já foi paga a comissão ao Vendedor.",;
		            "Pois o título com os dados especificados abaixo encontra-se com a comissão fechada. " + CRLF  +;
		            'Título: ' + _cNumero + ' - '  + 'Parcela: ' + _cParcela + ' - ' +;
		            'Prefixo: '+ _cSerie  + CRLF  + 'Cliente: ' + _cCliente + ' - ' + 'Loja: ' + _cLoja  + CRLF  +;
		            'Sequencia da baixa: '+ _cSeq )	 
	EndIf     
	
	//Verifica se podera ser realizada a exclusao da comissao de debito
	//gerada por uma baixa, o padrao do sistem nao trata esta questao.
	If _lRet .And. _cTipo == 'NCC'         
  
		DBSelectArea("SE3")					 
		SE3->(dbOrderNickName("IT_COMISSA"))//E3_FILIAL+E3_NUM+E3_SERIE+E3_PARCELA+E3_TIPO+E3_CODCLI+E3_LOJA+E3_SEQ                                                                                           
		If SE3->(DBSeek(xFilial("SE3") + _cNumero + _cSerie + _cParcela + _cTipo + _cCliente + _cLoja + _cSeq))
		     
			While SE3->(!Eof()) .And.;
			      SE3->E3_FILIAL == xFilial("SE3") .And. SE3->E3_NUM == _cNumero .And. SE3->E3_SERIE == _cSerie .And. SE3->E3_PARCELA == _cParcela .And.;
			      SE3->E3_TIPO == _cTipo .And. SE3->E3_CODCLI == _cCliente .And. SE3->E3_LOJA == _cLoja .And. SE3->E3_SEQ == _cSeq
			        	      
					//Verifica se o debito da comissao foi gerado a partir da baixa de uma NCC.
					If AllTrim(SE3->E3_I_ORIGE) == 'SACI008'
					
						RecLock("SE3",.F.) 
						
							dbDelete()
									
						SE3->(MSUnLock())     
					
					EndIf
			      	
			SE3->(DBSkip())
			EndDo      		
		EndIf   	
	EndIf          

EndIf

FWRestArea(_aAreaSE1)
FWRestArea(_aAreaSE5)
FWRestArea(_aAreaSE3)
FWRestArea(_aAreaSEF)
FWRestArea(_aArea)

Return _lRet 
