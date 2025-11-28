/*  
===================================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===================================================================================================================================
      Autor   |   Data   |                                             Motivo                                          
===================================================================================================================================
Josué Danich  | 14/12/18 | Chamado 27023. Inclusão de log de corte do pedido. 
Josué Danich  | 03/01/18 | Chamado 27510. Ajuste de log de corte só para venda de PA. 
Julio Paz     | 23/01/19 | Chamado 27797. Alterar consulta específica tabela SX5 = 'Z1" para não exibir chaves '98' e '99'.
Julio Paz     | 23/09/19 | Chamado 29932. Inclusão de rotina de envio de e-mail na exclusão de pedido de vendas do portal.  
Julio Paz     | 10/06/20 | Chamado 33220. Alterar log para gravar transferência ao excluir Pedidos de origem transferência.
Julio Paz     | 10/11/20 | Chamado 34587. Inclusão novas funcionalidades na rotina integração webservice Italac x DeuEasy.
Jerry         | 18/11/20 | Chamado 34673. Corrigido Parametros enviados na função Grava Monitor. 
Julio Paz     | 30/11/20 | Chamado 34752. Corrigir a gravação de Log, na transferência de Pedidos de Vendas. 
Julio Paz     | 02/08/21 | Chamado 37304. Gravar no Log de transferência de Pedidos de Vendas o motivo da transferência. 
Alex Wallauer | 19/10/22 | Chamado 41508. Colocado ISINCALLSTACK("U_MOMS066") Para não perguntar o MOTIVO DO CORTE.
Alex Wallauer | 03/01/22 | Chamado 42203. Colocado ISINCALLSTACK("U_IT_OPERTRIANGULAR") Para não perguntar o MOTIVO DO CORTE.
Alex Wallauer | 19/10/22 | Chamado 43081. Colocado ISINCALLSTACK(U_MOMS066) Para não mudar o MOTIVO DO CORTE escolhido em Tela.
Julio Paz     | 23/08/23 | Chamado 40530. Inclusão dos dados itens de pedidos de vendas no e-mail de exclusão do Pedido vendas.
Julio Paz     | 29/09/23 | Chamado 45043. Alterado para não exibir mensagem quando vindo da função MSEXEAUTO().
Alex Wallauer | 08/11/23 | Chamado 45503. Colocado !ISINCALLSTACK("U_AOMS108") para não mudar o MOTIVO DO CORTE escolhido.
Alex Wallauer | 08/02/24 | Chamado 44782. Jerry. Ajustes para a nova opcao de tipo de entrega: O = Agendado pelo Op.Log.
Julio Paz     | 21/03/24 | Chamado 46665. Jerry. Corrigir o envio de e-mail na exclusão de pedidos de vendas.
Lucas Borges  | 23/07/25 | Chamado 51340. Ajustar função para validação de ambiente de teste
===================================================================================================================================
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Jerry    - Alex Wallauer - 23/09/24 - 01/10/24 - 48287   - Alteração para a tela de corte e o envio de e-mail depender do parametro IT_TPOPER.
Jerry    - Igor Melgaço  - 03/02/25 - 20/03/25 - 39201   - Ajustes para execução pelo MOMS072
==============================================================================================================================================================
*/    
  
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
 
#Include "TOTVS.ch"

//====================================================================================================
// Definicoes de Variáveis Estáticas.
//====================================================================================================
Static _aDadosEmai := {}

/*
===============================================================================================================================
Programa----------: A410EXC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 16/10/2015
===============================================================================================================================
Descrição---------: Validação da exclusão dos pedidos de venda - Chamado 12081
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A410EXC()

Local _lRet			:= .T.
Local _aArea	    := FWGetArea()
Local _aSC6         := SC6->(GetArea())
Local _cCodArmaz	:=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "C6_LOCAL"	} )
Local _cCodPro		:=	aScan( aHeader , {|x| Upper( AllTrim( x[2] ) ) == "C6_PRODUTO"	} )
Local _cmens		:= ""
Local _aRet			:= {}
Local _nI 			:= 1
Local nLinha        := 10
Local _nCol			:= 15
Local _cAssunto, _cBody, _cEmail, _cNomeCli
Local _nPosMTRAN    := 0, _cMotivo 
Local _cTipoAgen    := "" 
Local _cTpOper      := U_ITGetMv("IT_TPOPER", "01,42,08,12,15,24,25,26")


Private _aItemPedV := {}   

_lRet := U_RetMT410ACE()//Verifica se o PE MT410ACE.PRW devolveu .F.
If Type("lMsErroAuto") = "L" .And. !_lRet .And. !lMsErroAuto//Só altera o conteudo do lMsErroAuto se ele tiver Falso e o retorno For falso
   lMsErroAuto:=!_lRet//Só Joga verdadeiro de For o caso
EndIf
If !_lRet
   Return _lRet 
EndIf

//================================================================================
// Configura ambiente quando uma exclusão For da rotina de MSExecAuto( {|x,y,z| Mata410(x,y,z) }
// pedidos de vendas. A mensagem de erro é retornada na variavel _cAOMS074Vld.
// Para exibir mensagens, utilizar neste ponto de entrada a função U_MT_ITMSG().
//================================================================================
Private _lMsgEmTela := .T.

If Type("_cAOMS074") <> "U"
   _lMsgEmTela := .F.
EndIf 

//========================================================================================
//Validação de usuário x filial x armazém
//========================================================================================
If _lRet

	_cusr := AllTrim(RetCodUsr())
	
	For _nI := 1 to Len(acols)

		If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas
	
			//============================================
			//Valida armazémxprodutoxfilialxusuário
			//============================================
			_aRet:= U_ACFG004E(_cusr, AllTrim(xFilial("SC6")), AllTrim(acols[_nI][_cCodArmaz]),AllTrim(acols[_nI][_ccodPro]),.F.)
		
			//se ainda está valido verifica se não teve erro
			If _lRet
		
		  	   _lRet:= _aRet[1]
		
			EndIf
		
			// adiciona armazens com problema se ainda não estiver na mensagem
			If Empty(_cmens)
		
				_cmens += _aRet[2]
			
			ElseIf !(_aRet[2]$_cmens) .And. !(Empty(_aRet[2])) 
		
				_cmens += ", " + _aRet[2]
			
			EndIf

	
		EndIf

	Next

	//============================================
	//Mostra lista de armazéns com problema
	//============================================
	If !(_lRet)
	   
		U_MT_ITMSG( 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' +  _cmens, "Atenção", ;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de Custos.' ,1 )
	
	EndIf

EndIf

//Solicita motivo de corte por exclusão
//Não é chamado pela exclusão múltipla que tem tela própria de motivo de corte
//Não é chamado pelo desmembramento que não pé considerado corte
//Não chama no corte da tela de central de pvs que tem a própria chamada de motivo
//Não chama da transferência
//Não chama se o pedido de vendas não For "N" ou não tiver produto PA em venda
_lvcorte := .F.

If SC5->C5_TIPO == "N" .And. AllTrim(SC5->C5_I_OPER) $ _cTpOper
   _lvcorte := .T.

	//SC6->(DBSetOrder(1))
	//If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	//	While SC5->C5_NUM == SC6->C6_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL	
	//		If AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPO")) == "PA" .And. Posicione("ZAY",1,xFilial("ZAY")+SC6->C6_CF,"ZAY_TPOPER") == "V" 
	//			_lvcorte := .T.
	//		EndIf	
	//		SC6->(DBSkip())
	//	EndDo
	//EndIf
	
EndIf


If _lRet .And. _lvcorte .And. !ISINCALLSTACK("U_AOMS108")           .AND.;
                              !ISINCALLSTACK("U_AOMS099")           .AND.;
							  !ISINCALLSTACK("U_AOMS109")           .AND.;
							  !ISINCALLSTACK("U_AOMS032")           .AND.;
							  !ISINCALLSTACK("U_MOMS066")           .AND.;
							  !ISINCALLSTACK("U_MOMS072")           .AND.;
							  !ISINCALLSTACK("U_IT_OPERTRIANGULAR") .AND.;
							  !ISINCALLSTACK("U_INCPEDVEND")

	_lRet := .F. //Deixa em false para bloquear se o usuário fechar a dialog no X

	_cQuery := " SELECT "
	_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
	_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
	_cQuery += " WHERE "
	_cQuery += "     D_E_L_E_T_ = ' ' AND TRIM(X5_CHAVE) <> '98' AND TRIM(X5_CHAVE) <> '99' "
	_cQuery += " AND X5_TABELA  = 'Z1' "
	_cQuery += " ORDER BY X5_CHAVE "

	If Select("TMPCF") > 0 
		("TMPCF")->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , 'TMPCF' , .F. , .T. )

	_amotivs := {}

	While TMPCF->( !Eof() )
                               
		aAdd( _amotivs , AllTrim( TMPCF->CHAVE ) + " - " + AllTrim( TMPCF->DESCRI ) )

		TMPCF->( DBSkip() )
	EndDo

	("TMPCF")->( DBCloseArea() )

	Public _cmotivs := _AMOTIVS[1]

	DEFINE MSDIALOG _oDlg2 TITLE ("Corte por exclusão de PV (A410EXC)") From 0,0 To 325, 650 OF oMainWnd PIXEL
                                                                       
	@ 01,_nCol Say OemToAnsi("Selecione o motivo para corte:")
	nLinha+=12

	_omotiv := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_cmotivs:=u,_cmotivs)}, _amotivs,250,20,_oDlg2,,;
							,,,,.T.,,,,,,,,,'') //40

	nLinha+=38

	@ nLinha,_nCol    Button "OK" SIZE 41,15 ACTION ( _lRet := .T.,_oDlg2:End()) Pixel 
	@ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( _oDlg2:End() ) Pixel 

	ACTIVATE MSDIALOG _oDlg2 
	
	If !_lRet
	
		U_MT_ITMSG("Não foi selecionado motivo de corte, pedido não será excluido!","Atenção",,1)
		
	EndIf
ElseIf _lRet .And. _lvcorte .And. ISINCALLSTACK("U_AOMS032")

	_cmotivs := "96"  //Exclusão por transferência
ElseIf _lRet .And. _lvcorte .And. ISINCALLSTACK("U_MOMS072")

	_cmotivs := "18"  //A mais de 60 dias na carteira
ElseIf _lRet .And. !ISINCALLSTACK("U_MOMS066") .And. !ISINCALLSTACK("U_AOMS108")

	_cmotivs := "95"  //Exclusão de pedido não venda

EndIf

//==============================================
// Obtem a descrição do motivo.
//==============================================
_cDescMotiv := ""
If Type("_cmotivs") <> "U"
   _cDescMotiv := Tabela("Z1",SubStr(_cmotivs,1,2),.F.)
EndIf 

//Grava log de exclusão e corte do pedido de vendas
If _lRet .And. !ISINCALLSTACK("U_IT_OPERTRIANGULAR")//Não grava nada quando For exclusao do pedido triangular 05
        If ISINCALLSTACK("U_AOMS032")
		   _aDadaux := {}
		   _nPosMTRAN := aScan(_aCabecPV,{|x| x[1] == 'C5_I_MTRAN'})
		   
		   aAdd( _aDadAux , { 'C5_FILIAL'	, SC5->C5_FILIAL	, _cFilTran	} )
           If _nPosMTRAN > 0 
		      _cMotivo   := _aCabecPV[_nPosMTRAN,2]  
			  aAdd( _aDadAux , { 'C5_I_MTRAN', "" , _cMotivo } )
		   EndIf 
        Else 
		   _aDadaux := {}
		   aAdd( _aDadAux , { 'C5_FILIAL'	, SC5->C5_FILIAL	, ''		} )
		   aAdd( _aDadAux , { 'C5_NUM'		, SC5->C5_NUM		, ''		} )
		   aAdd( _aDadAux , { 'C5_CLIENTE'	, SC5->C5_CLIENTE	, ''		} )
		   aAdd( _aDadAux , { 'C5_LOJACLI'	, SC5->C5_LOJACLI	, ''		} )
		   aAdd( _aDadAux , { 'C5_EMISSAO'	, SC5->C5_EMISSAO	, SToD('')	} )
		   aAdd( _aDadAux , { 'C5_I_DTENT'	, SC5->C5_I_DTENT	, SToD('')	} )
		EndIf 
		
		If !ISINCALLSTACK("U_AOMS032") 
		   U_ITGrvLog( _aDadAux , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) , "E" , RetCodUsr() , Date() , Time() )
		Else // Rotina chamada na exclusão de pedidos que deram origem a transferência de pedidos.
		   U_ITGrvLog( _aDadAux , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) , "T" , RetCodUsr() , Date() , Time() )
		   U_GrvMonitor(SC5->C5_FILIAL,SC5->C5_NUM,_cmotivs,"Exclusao","S",SC5->C5_I_DTENT,SC5->C5_I_DTENT,SC5->C5_I_DTENT)     
		EndIf  

EndIf 

//======================================================================
// Verifica se o Pedido de Vendas Excluido possui origem do portal.
// Caso afirmativo, envia e-mail para o vendedor avisando.
//======================================================================
If _lRet .And. !ISINCALLSTACK("U_AOMS032")
     

   //SZW->(DBSetOrder(12)) // ZW_NUMPED // Ordem C
   If AllTrim(SC5->C5_I_OPER) $ _cTpOper //SZW->(DBSeek(SC5->C5_NUM))
      //========================================================================
	  // Carrega dados do Pedido de Vendas para Envio do E-Mail.
	  //========================================================================
	  U_A410GRVI() 

	  //======================================================================== 
      // Grava dados para Enviar E-Mail
	  //========================================================================
        _cEmail:= Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_EMAIL") 
		_cZPG_EMAIL:=""
        If !Empty(SC5->C5_ASSCOD)
           _cZPG_EMAIL:=AllTrim(Posicione("ZPG",1,xFilial("ZPG")+SC5->C5_ASSCOD,"ZPG_EMAIL"))
        EndIf
        If !Empty(_cZPG_EMAIL)
           _cEmail+=";"+Lower(_cZPG_EMAIL)
        EndIf

	  _cNomeCli := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")

      //If SC5->C5_I_ AGEND == "A" // A=AGENDADA;I=IMEDIATA;M=AGENDADA C/MULTA;P=AGUARD. AGENDA;R=REAGENDAR;N=REAGENDAR C/MULTA
      //   _cTipoAgen := "AGENDADA"
	  //ElseIf SC5->C5_I_ AGEND == "I" 
      //   _cTipoAgen := "IMEDIATA"
	  //ElseIf SC5->C5_I_ AGEND == "M"
      //   _cTipoAgen := "AGENDADA C/MULTA" 
	  //ElseIf SC5->C5_I_ AGEND == "P"
      //   _cTipoAgen := "AGUARD. AGENDA"
	  //ElseIf SC5->C5_I_ AGEND == "R"
      //   _cTipoAgen := "REAGENDAR"
	  //ElseIf SC5->C5_I_ AGEND == "N"
      //   _cTipoAgen := "REAGENDAR C/MULTA"
	  //EndIf 
      _cTipoAgen:=U_TipoEntrega(SC5->C5_I_AGEND)

	  _aFilial := FwLoadSM0()  // Posição 07 = Nome filial  // Posição 02 = codigo filial
      _nI := aScan(_aFilial,{|x| x[02] == SC5->C5_FILIAL})
	  _cNomeFil := AllTrim(_aFilial[_nI,07])

      _cAssunto := "Pedido de Vendas Numero: " + AllTrim(SC5->C5_NUM) +" - "+ AllTrim(_cNomeCli)  + ", foi excluido do sistema Protheus. "
      _cBody    := "<b>Prezado Sr(a),</b>"
      _cBody    += '<br><br>'
      _cBody    += '&nbsp;&nbsp;&nbsp; Pedido de vendas excluído do Sistema Protheus.' + '<br>'
      _cBody    += '<br>'
      _cBody    += '<table border="1">'
      _cBody    += '<tr>'
      _cBody    += '<th bgcolor="#87CEEB">FILIAL</th>'
      _cBody    += '<th bgcolor="#87CEEB">NOME</th>'
      _cBody    += '<th bgcolor="#87CEEB">CLIENTE</th>'
      _cBody    += '<th bgcolor="#87CEEB">LOJA</th>'
      _cBody    += '<th bgcolor="#87CEEB">PEDIDO</th>'
	  _cBody    += '<th bgcolor="#87CEEB">EMISSÃO</th>'
      _cBody    += '<th bgcolor="#87CEEB">DATA ENTREGA</th>'
	  _cBody    += '<th bgcolor="#87CEEB">TIPO DE ENTREGA</th>'
	  _cBody    += '<th bgcolor="#87CEEB">PEDIDO PORTAL</th>'
	  _cBody    += '<th bgcolor="#87CEEB">MOTIVO EXCLUSÃO PED.VEND.</th>'
      _cBody    += '</tr>'
      _cBody    += '<tr>'
      _cBody    += '<td>'+ SC5->C5_FILIAL + "-" + _cNomeFil + '</td>'
	  _cBody    += '<td>'+ _cNomeCli +'</td>'      
      _cBody    += '<td align="center">'+ SC5->C5_CLIENTE +'</td>'
      _cBody    += '<td align="center">'+ SC5->C5_LOJACLI  +'</td>'
	  _cBody    += '<td align="center">'+ SC5->C5_NUM    +'</td>'
      _cBody    += '<td align="center">'+ DToC(SC5->C5_EMISSAO) +'</td>'
      _cBody    += '<td align="center">'+ DToC(SC5->C5_I_DTENT) +'</td>'
      _cBody    += '<td align="center">'+ _cTipoAgen +'</td>'
      _cBody    += '<td align="center">'+ SC5->C5_I_IDPED +'</td>'
	  _cBody    += '<td>'+ _cDescMotiv+'</td>'
      _cBody    += '</tr>'

      _cBody    += '<tr>'
      _cBody    += '<th bgcolor="#87CEEB">PRODUTO</th>'          // 1
      _cBody    += '<th bgcolor="#87CEEB">DESCRIÇÃO</th>'        // 2
      _cBody    += '<th bgcolor="#87CEEB">PREÇO VENDA</th>'      // 3 
      _cBody    += '<th bgcolor="#87CEEB">%CONTRATO</th>'        // 4
      _cBody    += '<th bgcolor="#87CEEB">PREÇO NET</th>'        // 5
	  _cBody    += '<th bgcolor="#87CEEB">PREÇO TABELA</th>'     // 6
      _cBody    += '<th bgcolor="#87CEEB">QUANTIDADE</th>'       // 7 
      _cBody    += '<th bgcolor="#87CEEB">UNIDADE MEDIDA</th>'   // 8
      _cBody    += '<th bgcolor="#87CEEB">TOTAL</th>'            // 9
      _cBody    += '<th bgcolor="#87CEEB">PEDIDO CLIENTE</th>'   // 10	  	  	  
      _cBody    += '</tr>'

      For _nI := 1 To Len(_aItemPedV)
          _cBody    += '<tr>'
          _cBody    += '<td>'+ _aItemPedV[_nI,1]  + '</td>'                                                  // Código           // 1
		  _cBody    += '<td>'+ _aItemPedV[_nI,2]  + '</td>'                                                  // Descrição        // 2
		  _cBody    += '<td align="right">'+ AllTrim( Transform(_aItemPedV[_nI,3] , '@E 999,999,999,999.99' ) )  + '</td>' // Preço Venda      // 3
		  _cBody    += '<td align="right">'+ AllTrim( Transform(_aItemPedV[_nI,4] , '@E 999,9999' ) )            + '</td>' // % Contrato(2)    // 4
		  _cBody    += '<td align="right">'+ AllTrim( Transform(_aItemPedV[_nI,5] , '@E 999,999,999,999.99' ) )  + '</td>' // Preço Net(3)     // 5
		  _cBody    += '<td align="right">'+ AllTrim( Transform(_aItemPedV[_nI,6] , '@E 999,999,999,999.99' ) )  + '</td>' // Preço Tabela(1)  // 6
		  _cBody    += '<td align="right">'+ AllTrim( Transform(_aItemPedV[_nI,7] , '@E 99,999,999,999.9999' ) ) + '</td>' // Quant.           // 7
		  _cBody    += '<td align="center">'+ _aItemPedV[_nI,8]  + '</td>'                                                  // Unid.Medida      // 8
		  _cBody    += '<td align="right">'+AllTrim( Transform( _aItemPedV[_nI,9], '@E 999,999,999,999.99' ) )   + '</td>' // Total            // 9
		  _cBody    += '<td>'+ _aItemPedV[_nI,10] + '</td>'                                                  // Pedido Cliente   // 10
          _cBody    += '</tr>'
	  Next 

      _cBody    += '</table>'
      _cBody    += '<br><br>'
      _cBody    += '    <tr>'
      _cBody    += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
      _cBody    += '      <td class="itens" align="left" > [ '+ GETENVSERVER() +' ] / <b>Fonte:</b>[ A410EXC.PRW ]</td>'
      _cBody    += '    </tr>'

      _aDadosEmai := {_cAssunto, _cBody, _cEmail} 
      //A410EXECA(_cAssunto, _cBody, _cEmail) // Envia o e-mail.

   EndIf
EndIf 

FWRestArea(_aarea)
SC6->(FWRestArea(_aSC6))

If Type("lMsErroAuto") = "L" .And. !_lRet .And. !lMsErroAuto//Só altera o conteudo do lMsErroAuto se ele tiver Falso e o retorno For falso
   lMsErroAuto:=!_lRet//Só Joga verdadeiro de For o caso
EndIf

Return( _lRet )
          
/*
===============================================================================================================================
Programa----------: A410EXECA
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/02/2019
===============================================================================================================================
Descrição---------: Rotina de envio de E-mail para exclusão de pedidos de vendas originários da efetivação de pedidos do
                    portal de pedidos de vendas.
===============================================================================================================================
Parametros--------: _cAssunto = Assunto do e-mail
                    _cBody    = Conteúdo do e-mail.
					_EmailVend = E-Mail do vendedor.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A410EXECA(_cAssunto, _cBody, _EmailVend)
Local _aConfig	:= U_ITCFGEML('') // Configurações do servidor de envio de e-mail.
Local _cEmlLog  := ""
Local _cEmail   := _EmailVend
Local _cEmailCC := AllTrim(UsrRetMail(__cUserId))

Begin Sequence
     
   U_ITENVMAIL( "workflow@italac.com.br", _cEmail, _cEmailCC ,, _cAssunto, _cBody     , , _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

   _cEmlLog := Upper(_cEmlLog)
   
   If !Empty( _cEmlLog ) .And. "SUCESSO" $ _cEmlLog
      U_ItConOut("[FINA010A] - Envio de e-mail na Exclusão de Pedidos de Vendas Originários do Portal.")
      U_ItConOut(_cEmlLog)
   Else
      U_ItConOut("[FINA010A] - Falha no envio de e-mail na Exclusão de Pedidos de Vendas Originários do Portal.")
      U_ItConOut("[FINA010A] - " + _cAssunto )
      U_ItConOut(_cEmlLog)
   EndIf

End Sequence

Return			   

/*
===============================================================================================================================
Programa----------: A410GRVI
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/08/2023
===============================================================================================================================
Descrição---------: Grava os dados dos itens dos pedidos de vendas em variável estática, para envio de e-mail de exclusão de
                    Pedido de Vendas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A410GRVI()
Local _nRegAtu := SC6->(Recno())
Local _nPerCont
Local _nPrcNet
Local _nPrcTab 

Begin Sequence 
   _aItemPedV := {}

   DA1->(DBSetOrder(1)) // DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM

   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO 
   SC6->(MsSeek(SC5->C5_FILIAL+SC5->C5_NUM))
   While ! SC6->(Eof()) .And. SC6->C6_FILIAL + SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM
      _nPerCont := 0
	  _nPrcNet  := 0
      _nPrcTab  := 0
      //============================================================================
      // Função:  U_veriContrato
      // Retorno:  1 - Armazena o valor do desconto																			
      //		   2 - Se o contrato esta aprovado																				
      //		   3 - Se contrato esta com a data de vigencia valida															
      //		   4 - Numero do contrato	
      //===========================================================================
	  _aPerCont := U_veriContrato( SC5->C5_CLIENTE , SC5->C5_LOJACLI , SC6->C6_PRODUTO )
	  If _aPerCont[2] // Se o contrato esta aprovado.
	     _nPerCont := _aPerCont[1]
	  EndIf 

      If DA1->(MsSeek(xFilial("DA1")+SC5->C5_I_TAB+SC6->C6_PRODUTO))
         If SC6->C6_I_FXPES == 3 
		    _nPrcTab := DA1->DA1_I_PRF3
		 ElseIf SC6->C6_I_FXPES == 2
		    _nPrcTab := DA1->DA1_I_PRF2		 
		 ElseIf SC6->C6_I_FXPES == 1
		    _nPrcTab := DA1->DA1_I_PRF1
         EndIf 
	  EndIf 
	  If _nPerCont > 0
         _nPrcNet := (SC6->C6_PRCVEN - ( ( _nPerCont * SC6->C6_PRCVEN ) / 100 ))
	  Else 
         _nPrcNet := SC6->C6_PRCVEN
	  EndIf

      aAdd(_aItemPedV,{SC6->C6_PRODUTO,; // Código           // 1
                       SC6->C6_DESCRI,;  // Descrição        // 2
                       SC6->C6_PRCVEN,;  // Preço Venda      // 3
                       _nPerCont,;       // % Contrato(2)    // 4
                       _nPrcNet,;        // Preço Net(3)     // 5
                       _nPrcTab,;        // Preço Tabela(1)  // 6
                       SC6->C6_UNSVEN,;  // Quant.           // 7
                       SC6->C6_SEGUM,;   // Unid.Medida      // 8
                       SC6->C6_VALOR,;   // Total            // 9
                       SC6->C6_PEDCLI})  // Pedido Cliente   // 10

      SC6->(DBSkip())
   EndDo

End Sequence

SC6->(DBGoTo(_nRegAtu))

Return 

/*
===============================================================================================================================
Programa----------: A410EXEM
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/02/2019
===============================================================================================================================
Descrição---------: Na efetivação da exclusão do pedido de vendas, esta função roda a rotina de envio de e-mail passando
                    como parâmetro as variáveis estática com os dados do Pedido de vendas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A410EXEM()

Begin Sequence

   //============================================================================
   // _aDadosEmai := {_cAssunto, _cBody, _cEmail} 
   // _cAssunto    = Assunto do e-mail
   // _cBody       = Conteúdo do e-mail.
   // _EmailVend   = E-Mail do vendedor.
   //============================================================================
   If ! Empty(_aDadosEmai)	  
      A410EXECA(_aDadosEmai[1],_aDadosEmai[2], _aDadosEmai[3])
	  _aDadosEmai := {}
   EndIf

End Sequence 

Return 
