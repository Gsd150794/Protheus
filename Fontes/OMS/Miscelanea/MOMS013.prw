/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/07/2018| chamado 25429. Exibir comissões pendentes de meses anteriores em tela de conf.para fechamento.
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
==============================================================================================================================================================
*/

#Include "TOTVS.ch"  
#define	MB_OK

/*
===============================================================================================================================
Programa----------: MOMS013
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 14/03/2011
Descrição---------: Rotina responsavel por realizar o fechamento da comissao na baixa
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS013()
                       
Local _oGetDtFech 
Local _oSay1
Local _oSay2     
Local _nOpca     := 0  
Local _cDataF    := GetMv("IT_COMFECH")  // Data do fechamento
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))

Private _cDtFecham := StrZero(_nmes,2)+"/"+AllTrim(Str(_nano))
Private _aRecnoSE3 := {}

Static _oDlg

DEFINE MSDIALOG _oDlg TITLE "ROTINA DE FECHAMENTO DA COMISSÃO" FROM 000, 000  TO 200, 500 COLORS 0, 16777215 PIXEL 
_oDlg:lMaximized:= .F.
	_oPanel := TPanel():New(0,0,'',_oDlg,, .T., .T.,, ,40,90,.T.,.T. )

    @ 007, 017 Say _oSay1 PROMPT "Esta rotina é responsável por efetuar o fechamento mensal da comissão de acordo com o mês e ano informados pelo usuário." SIZE 217, 017 OF _oPanel COLORS 0, 16777215 PIXEL
    @ 035, 080 Say _oSay2 PROMPT "Mês/Ano de fechamento:" SIZE 069, 007 OF _oPanel COLORS 0, 16777215 PIXEL
    @ 042, 080 MSGET _oGetDtFech VAR _cDtFecham SIZE 095, 011 OF _oPanel PICTURE "@R 99/9999" WHEN .F. COLORS 0, 16777215 PIXEL
     
ACTIVATE MSDIALOG _oDlg ON INIT (EnchoiceBar(_oDlg,{|| IIf(MOMS013VD(),Eval({|| _nOpca:= 1,_oDlg:End(),MsgRun("AGUARDE, PROCESSANDO O FECHAMENTO DA COMISSÃO.",,{||CursorWait(), MOMS013Q("",4) , CursorArrow()})}),) },{|| _nOpca:= 0,_oDlg:End()},,),_oPanel:align:= CONTROL_ALIGN_TOP)   

Return     
                 
/*
===============================================================================================================================
Programa----------: MOMS013Q
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 14/03/2011
Descrição---------: Funcao responsavel por armazenar as querys utilizadas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS013Q(_cAlias,_nOpcao) 

Local _cFiltro:= "%"         
Local _cUpdate:= ""         
Local lSqlOk
Local _cDataF    := GetMv("IT_COMFECH")  // Data do fechamento
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))+1
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))

Do Case
                                    
	//================================================================================
	//Verifica se existem lancamentos de comissao em aberto com uma
	//data inferior a data de fechamento informada pelo usuario.   
   	//================================================================================
	
	Case _nOpcao == 1      
			
		_cFiltro+= " AND SubStr(E3_EMISSAO,1,6) < '" + SubStr(_cDtFecham,4,4) +  SubStr(_cDtFecham,1,2) + "'"
		_cFiltro+= "%"
		
		// COUNT(*) NUMREG
		 
		BeginSql alias _cAlias			
			SELECT
			      R_E_C_N_O_ NUMREG
			FROM
			      %Table:SE3%
			WHERE
			      D_E_L_E_T_ = ' '
			      AND E3_I_FECH <> 'S'			
			      %exp:_cFiltro%	      			 
           EndSql 
                                  
	   //==============================================================
	   //Verifica se ja houve fechamento para o mes/ano informados
	   //pelo usuario.                                            
	   //==============================================================
	   
	Case _nOpcao == 2  
       
    	_cFiltro+= " AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cDtFecham,4,4) +  SubStr(_cDtFecham,1,2) + "'"
		_cFiltro+= "%"    
       
    	BeginSql alias _cAlias       		
     			SELECT
				      COUNT(*) NUMREG
				FROM
				      %Table:SE3%
				WHERE
				      D_E_L_E_T_ = ' '
				      AND E3_I_FECH = 'S'			
				      %exp:_cFiltro%       		             
    	EndSql    
  	
		
		//==========================================================================
		//Realiza a atualizacao do fechamento da comissao de pagamento de 
		//acordo com o Mes/Ano de fechamento fornecido pelo usuario.      
		//==========================================================================
		
	Case _nOpcao == 4   
		 
		_cUpdate := "UPDATE " 
		_cUpdate +=	  RetSqlName("SE3") 
		_cUpdate += " SET E3_I_FECH = 'S' " 
		_cUpdate += " ,E3_I_DTFEC = '" + DToS(date())       + "' " 
		_cUpdate += " ,E3_I_HRFEC = '" + SubStr(TIME(),1,5) + "' " 
		_cUpdate += " ,E3_I_USRFE = '" + FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]        + "' " 
		_cUpdate += " ,E3_DATA = '" + DToS( Date() ) + "'"  
		_cUpdate += "WHERE D_E_L_E_T_ = ' '"
		_cUpdate += " AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cDtFecham,4,4) +  SubStr(_cDtFecham,1,2) + "'"
		_cUpdate += " AND E3_DATA < '20010101'"
		lSqlOk := !(TCSqlExec(_cUpdate) < 0)
		
		_cUpdate := "UPDATE " 
		_cUpdate +=	  RetSqlName("SE3") 
		_cUpdate += " SET E3_I_FECH = 'S' " 
		_cUpdate += " ,E3_I_DTFEC = '" + DToS(date())       + "' " 
		_cUpdate += " ,E3_I_HRFEC = '" + SubStr(TIME(),1,5) + "' " 
		_cUpdate += " ,E3_I_USRFE = '" + FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]        + "' " 
		_cUpdate += "WHERE D_E_L_E_T_ = ' '"
		_cUpdate += " AND SubStr(E3_EMISSAO,1,6) = '" + SubStr(_cDtFecham,4,4) +  SubStr(_cDtFecham,1,2) + "'"
		_cUpdate += " AND E3_DATA > '20010101'"
		lSqlOk2 := !(TCSqlExec(_cUpdate) < 0)
		
										
		//==========================================================================
		//Ocorreu um erro ao executar a atualizacao do fechamento da comissao.
		//==========================================================================
				
		If !lSqlOk .Or. !lSqlOk2        
				
			xMagHelpFis("INFORMAÇÃO",;
	       			"Não foi possível realizar a atualização do fechamento da comissão para o seguinte Mês/Ano: " + _cDtFecham,;
	       			"Favor contactar o departamento de informática informando de tal problema: " + TcSqlError())    	              	            												            					
							
			//==========================================================================
			//Caso nao ocorra erro na atualizacao do fechamento da comissao
			//atualiza o parametro IT_COMFECH com o ultimo Mes/Ano de      
			//fechamento da comissao.                                      
			//==========================================================================
							
		Else

			//=========================================================================================
			//grava log de atualização para o fechamento na tabela de gestão de fechamento de comissão
			//=========================================================================================
	
			If _nmes == 13

  				_nmes := 1
  				_nano += 1

			EndIf

			PutMV("IT_COMFECH",StrZero(_nmes,2) + "/" + StrZero(_nano,4))
	
			RecLock("ZC8",.T.)
 
 			ZC8->ZC8_FILIAL     := xFilial("ZC8")   
			ZC8->ZC8_SEQ        := U_MOMS009C()  //Gera nova sequência do ZC8
			ZC8->ZC8_ROTINA     := "Fechamento mensal"
			ZC8->ZC8_DATA       := Date()
			ZC8->ZC8_HORA       := Time()
			ZC8->ZC8_USER       := cUserName
			ZC8->ZC8_CODUSU     := __cUserId
			ZC8->ZC8_OBS        := _cDtFecham
			ZC8->ZC8_COMP       := _cDtFecham
 
			MSUnLock()
	
			RecLock("ZC9",.F.)
 
 			ZC9->ZC9_STATUS     := "2"   
 
 			MSUnLock()
	
			RecLock("ZC9",.T.)
 
			ZC9->ZC9_FILIAL     := xFilial("ZC8")   
			ZC9->ZC9_SEQ        := U_MOMS009H()  //Gera nova sequência do ZC9
			ZC9->ZC9_COMP       := StrZero(_nmes,2) + "/" + StrZero(_nano,4)
			ZC9->ZC9_STATUS     := "0"

			MSUnLock()
								 	    
			MsgInfo("Fechamento da comissão efetuado com sucesso!")   
															     						            					
		EndIf
		
		U_ITLOGACS('MOMS013')
            
EndCase     

Return

/*
===============================================================================================================================
Programa----------: MOMS013VD2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/12/2015
Descrição---------: Valida execução do fechamento de comissões
Parametros--------: Nenhum
Retorno-----------: Lógico liberando ou não a execução do fechamento de comissões
===============================================================================================================================
*/
Static Function MOMS013VD2()

Local _aalertas  := {}
Local _cDataF    := GetMv("IT_COMFECH")  // Data do fechamento
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _cAlias	   := GetNextAlias()
Local _cseq      := ""
Local _aMsgItlist := {}, _aCabItList
Local _cTitulo, _lRet := NIL
Local _nI

//verifica parametro de fechamento de comissao
_aalertas := U_MOMS009VS()

//Verifica se usuário pode rodar a rotina
DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_ADMCMS == 'S')

    aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão para cálculo de comissões!") 
 
End If


_cDataf := StrZero(_nano,4)+StrZero(_nmes,2)+"01"

//verifica se não está fazendo fechamento o mês atual ou futuro
If AllTrim(Str(_nano))+AllTrim(StrZero(_nmes,2)) >= AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))

  aAdd(_aalertas,"Mês " + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + " não terminou ainda!") 
  
EndIf

//verifica se já foi liberado pelo financeiro
_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Fechamento Financeiro' "
_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and  D_E_L_E_T_ = ' ' and ZC8_FILIAL = '" +xFilial("ZC8") + "'"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

If (_cAlias)->( Eof() )

  aAdd(_aalertas,"Não existe um fechamento financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
  (_cAlias)->( DBCloseArea() )  
  
Else

	_cseq := AllTrim((_cAlias)->ZC8_SEQ)
	(_cAlias)->( DBCloseArea() )

	//verifica se já rodou recálculo de comissão após a liberação do financeiro

	_cAlias	:= GetNextAlias()

	_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA like 'Recalculo de Comissao%' "
	_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and  D_E_L_E_T_ = ' '  and ZC8_FILIAL = '" +xFilial("ZC8") + "'"
	
	DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
	DBSelectArea(_cAlias)

	If (_cAlias)->( Eof() )

  		aAdd(_aalertas,"Não existe um recálculo de comissão após a liberação do financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
       (_cAlias)->( DBCloseArea() )
  
	Else
	
		//verifica se já rodou cálculo de adicionais de comissão para bonificação
		(_cAlias)->( DBCloseArea() )
		_cAlias	:= GetNextAlias()

		_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Adicionais de Comissao' "
		_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and ZC8_OBS = '2 - Bonificações'"
		_cQuery += " and D_E_L_E_T_ = ' ' and ZC8_FILIAL = '" +xFilial("ZC8") + "'"

		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
		DBSelectArea(_cAlias)

		If (_cAlias)->( Eof() )

  			aAdd(_aalertas,"Não existe um cálculo de adicionais de bonificação após a liberação do financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
  			
  		EndIf
		
		(_cAlias)->( DBCloseArea() )
	
	EndIf
	
EndIf

//===================================================================================
//Verifica se nao existem outros meses em aberto antereriores ao 
//do que se esta tentando efetuar o fechamento.                  
//===================================================================================
_aCabItList := {"Filial","Vendedor","Nome Vendedor","No. Titulo","Dt Comissão","Serie N.F.","Cliente","Loja","Nome Cliente","Vlr.Base","% Vl.Base","Comissão","Data Pagto","Mensagem"}

_cAlias:= GetNextAlias()            
  
MOMS013Q(_cAlias,1)

DBSelectArea(_cAlias) 
(_cAlias)->(DBGoTop())

While ! (_cAlias)->(Eof())
   //If (_cAlias)->NUMREG > 0
   //	aAdd(_aalertas,"Existem comissões em aberto com o Mês/Ano inferior ao Mês/Ano informado para a realização do fechamento da comissão.(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")
   //EndIf   
      
   SE3->(DBGoTo((_cAlias)->NUMREG))
   
   aAdd(_aMsgItlist, {SE3->E3_FILIAL,;   // Filial
                      SE3->E3_VEND  ,;   // Vendedor
                      Posicione("SA3",1,xFilial("SA3")+SE3->E3_VEND,"A3_NOME"),; // Nome do Vendedor
                      SE3->E3_NUM   ,;   // No. Titulo
                      SE3->E3_EMISSAO,;  // Dt Comissão
                      SE3->E3_SERIE  ,;  // Serie N.F.
                      SE3->E3_CODCLI ,;  // Cliente
                      SE3->E3_LOJA   ,;  // Loja
                      Posicione("SA1",1,xFilial("SA1")+SE3->E3_CODCLI+SE3->E3_LOJA,"A1_NOME"),; // Mome do Cliente
                      SE3->E3_BASE   ,;  // Vlr.Base
                      SE3->E3_PORC   ,;  // % Vl.Base
                      SE3->E3_COMIS  ,;  // Comissão
                      SE3->E3_DATA   ,;  // Data Pagto
                      "Existem comissões em aberto com o Mês/Ano inferior ao Mês/Ano informado para a realização do fechamento da comissão.(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")" }) // Mensagem
   
   aAdd(_aRecnoSE3, SE3->(Recno()))
   
   (_cAlias)->(DBSkip())
EndDo


DBSelectArea(_cAlias) 
(_cAlias)->(DBCloseArea())

//===================================================================================
//Verifica se ja nao houve fechamento para a comissao para o        
//mes/ano informado, pois somente podera ser realizado um fechamento
//da comissao.                                                      
//===================================================================================

_cAlias:= GetNextAlias()            
  
MOMS013Q(_cAlias,2)

DBSelectArea(_cAlias) 
(_cAlias)->(DBGoTop())

If (_cAlias)->NUMREG > 0
        
	aAdd(_aalertas,"Não será possível realizar o fechamento da comissão para o Mês/Ano indicados, pois ja foi efetuado um fechamento para este Mês/Ano.(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")")

EndIf   

DBSelectArea(_cAlias) 
(_cAlias)->(DBCloseArea()) 


If Len(_aMsgItlist) > 0
   _cTitulo := "Validação de Outros Meses em Aberto Anteriores ao Mes de Fechamento"
   
   _lRet := U_ITListBox('Validações do Fechamento de Comissões (MOMS013)',_aCabItList,_aMsgItlist,.T.,1,_cTitulo)
   
   If _lRet .And. Empty(_aalertas) 
      
      For _nI := 1 To Len(_aRecnoSE3)
          SE3->(DBGoTo(_aRecnoSE3[_nI]))
          SE3->(RecLock("SE3",.F.))
          SE3->E3_I_FECH := 'S'
          
          SE3->(MSUnLock())
      Next
      
      For _nI := 1 To Len(_aMsgItlist)   
          ZGD->(RecLock("ZGD", .T.))
          ZGD->ZGD_FILIAL  := _aMsgItlist[_nI,1]    //  Filial
          ZGD->ZGD_VEND    := _aMsgItlist[_nI,2]    //  Vendedor
          ZGD->ZGD_NOMEVD  := _aMsgItlist[_nI,3]    //  Nome Vended
          ZGD->ZGD_NUM     := _aMsgItlist[_nI,4]    //  No. Titulo
          ZGD->ZGD_EMISSAO := _aMsgItlist[_nI,5]    //  Dt Comissão
          ZGD->ZGD_SERIE   := _aMsgItlist[_nI,6]    //  Serie N.F.
          ZGD->ZGD_CODCLI  := _aMsgItlist[_nI,7]    //  Cliente
          ZGD->ZGD_LOJA    := _aMsgItlist[_nI,8]    //  Loja
          ZGD->ZGD_NOMECL  := _aMsgItlist[_nI,9]    //  Nome Cliente
          ZGD->ZGD_BASE    := _aMsgItlist[_nI,10]   //  Vlr.Base
          ZGD->ZGD_PORC    := _aMsgItlist[_nI,11]   //  % Vl.Base
          ZGD->ZGD_COMIS   := _aMsgItlist[_nI,12]   //  Comissão
          ZGD->ZGD_DATA    := _aMsgItlist[_nI,13]   //  Data Pagto
          ZGD->ZGD_MENSAG  := _aMsgItlist[_nI,14]   //  Mensagem Vld
          ZGD->ZGD_USUARI  := __cUserId             //  Cod.Usuario
          ZGD->ZGD_DTLOG   := Date()                //  Dt.Grv.Log
          ZGD->(MSUnLock())      
      Next
   ElseIf ! _lRet .And. Empty(_aalertas)
          Return .F.      
   EndIf
EndIf

//se teve qualquer alerta na verificação monta mensagem e impede o processamento
If Len(_aalertas) > 0
  
    _cMensagem := "<html>"
	_cMensagem += "<body>"
	_cMensagem += "<strong>"
	_cMensagem += "<p>"
	_cMensagem += "Foram encontrados problemas com o processo!<br>"
	_cMensagem += "Fechamento não será efetuado, corrija o processo e execute novamente.<br>"
	_cMensagem += "</p>
	_cMensagem += "</strong>
	_cMensagem += "<hr>"
		
   For _nI = 1 to Len(_aalertas)
  
  		_cMensagem += "<p>"
		_cMensagem += _aalertas[_nI] 
		_cMensagem += "</p>
		If _nI < Len(_aalertas) 
		  _cMensagem += "<hr>"
		EndIf
		
	Next
	
	_cMensagem += "</body>"
	_cMensagem += "</html>"
				
	MessageBox(_cMensagem, "Problema no processo", MB_OK)
  
  	Return .F.
  	 
EndIf 

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS013VD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/12/2015
Descrição---------: Monta tela de validação de fechamento de comissão
Parametros--------: Nenhum
Retorno-----------: Lógico liberando ou não a execução do fechamento de comissões
===============================================================================================================================
*/
Static Function MOMS013VD()

Local _lRet     := .T.    

MsgRun("AGUARDE, PROCESSANDO VALIDAÇÕES NO FECHAMENTO DA COMISSÃO.",,{||CursorWait(), _lRet:= MOMS013VD2(), CursorArrow()})

Return _lRet
