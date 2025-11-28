/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/03/2024| Chamado 46480. Chamada da funcao U_M460Acertos para Acertar os Raterios de campos novos contra valores totais do RDC.
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: M460NOTA
Autor-----------: Alex Wallauer
Data da Criacao-: 13/04/2021 
Descrição-------: P.E. no final do faturamento de Cargas e Pedidos - CHAMADO 36078
Parametros------: Nenhum
Retorno---------: Lógico .T.
===============================================================================================================================
*/
User Function M460NOTA()

Private _aProd:={}
Private _aItens:= U_M460Lista()
Private _lRet := .T.

FWMsgRun( ,{|oProc|  U_M460Acertos(.T.) } , "Processando..." , "Acerto de Valores de Pedagios..." )

If Len(_aItens) > 0 
   FWMsgRun( ,{|oProc| _lRet := M460Val(oProc) } , "Processando..." , "Verificando Estoque..." )
EndIf

If Len(_aProd) > 0 .And. !_lRet
   _aCab:={'Produto','Descricao','Armazem',"Saldo Disponivel","Observacao"}
   FWMsgRun( ,{|oProc| M460Email(_aProd,_aCab,oProc) } , "Processando..." , "Enviando Email..." )
   U_ITListBox( 'Verificação do estoque dos pedidos da Carga apos faturamento! (M460NOTA)' , _aCab , _aProd , .T. , 1 , 'ESTORNE O FATURAMENTO E VALIDE OS MOVIMENTOS KARDEX, DUVIDAS ENTRE EM CONTATO COM DEPARTAMENTO FISCAL' )
EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: M460Val()
Autor-----------: Alex Wallauer
Data da Criacao-: 26/04/2021 
Descrição-------: Valida se os itens dos pedidos estão com estoque
Parametros------: Nenhum
Retorno---------: Lógico .T.
===============================================================================================================================
*/
Static Function M460Val(oProc)

Local _lRet  := .T.
Local _nSaldo:= 0 , I
Private _cPictQtde:="@E 999,999,999,999.999"

For I := 1 TO Len(_aItens)
    If oProc <> NIL
       oProc:cCaption := ("Vendo Estoque: "+_aItens[I,1] +"-"+ _aItens[I,2] )
       ProcessMessages()
    EndIf  

    _aSaldo:= CalcEst( _aItens[I,1] , _aItens[I,2] , dDataBase+1 ) 
    _nSaldo:= _aSaldo[1]
    _lErro :=(_nSaldo < 0)// SALDO NEGATIVO
    If _lErro
       aAdd( _aProd , { _aItens[I,1] ,AllTrim(Posicione("SB1",1,xFilial("SB1")+AllTrim(_aItens[I,1] ),"B1_DESC")), _aItens[I,2] , TRANS(_nSaldo,_cPictQtde) ,;
            'ESTORNE O FATURAMENTO E VALIDE OS MOVIMENTOS NO KARDEX, DUVIDAS ENTRE EM CONTATO COM DEPARTAMENTO FISCAL'} )
       _lRet :=.F.
    EndIf
Next

Return _lRet

/*
===============================================================================================================================
Programa----------: M460Email()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/11/2019
Descrição---------: Monta e envia email 
Parametros--------: _aTLinhas,_aCab,oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function M460Email(_aTLinhas,_aCab,oProc)

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local _nI , _aSizeOK:={}
Local cGetCc	:= ""
Local cGetPara	:= AllTrim(SuperGetMV("IT_MESTNEG",.T.,"sistema@italac.com.br"))
Local _cTot     := AllTrim(Str(Len(_aTLinhas)))
Local _nTam     := Len(_cTot)
Local _cNomeFil := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') )
Local cGetAssun := "Resultado do estoque apos Faturamento da(s) Carga(s): "+_aItens[1,3] 
Local cTit      := "Resultado do estoque apos Faturamento"
Local cErMens	:= "ESTORNE O FATURAMENTO E VALIDE OS MOVIMENTOS NO KARDEX, DUVIDAS ENTRE EM CONTATO COM DEPARTAMENTO FISCAL"

If IsInCallStack('MATA460A') //Faturamento por pedido
   cGetAssun := "Resultado do estoque apos Faturamento do(s) Pedido(s): "+_aItens[1,3] 
EndIf

If (Len(PSWRET()) # 0) // Quando nao For rotina automatica do configurador
   PswOrder(1)
   PswSeek(__cUserId,.T.)
   aUsuario:= PswRet()
   cGetCc  := LOWER(AllTrim(aUsuario[1,14]))+Space(150)// Pega e-mail do usuario
EndIf

If Empty(cGetPara)
   cGetPara:=cGetCc
EndIf   
_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cTit+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.itensV	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF;  color:#FF0000;}'//#FF0000
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados da alteração</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="30%"><b>Faturado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="30%"><b>Observações:</b></td>'
_cMsgEml += '      <td class="itensV" ><b>'+cErMens+'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

//          01   02   03   04   05 
_aSizeOK:={"10","50","05","15","25"}//{'Produto','Descricao','Armazem',"Saldo Estoque","Problema"}

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizeOK)))+'" class="grupos"><b>Estoque negativo de Produtos / Armazens</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[01]+'%"><b>'+_aCab[01]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[02]+'%"><b>'+_aCab[02]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[03]+'%"><b>'+_aCab[03]+'</b></td>'
_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizeOK[04]+'%"><b>'+_aCab[04]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%"><b>'+_aCab[05]+'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    #LISTAOK#'
_cMsgEml += '</table>'
_cMsgEml += '<br>'

_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [M460NOTA]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cOKLista:=""
_cGetLista:=""
_lEnvia:=.F.
For _nI := 1 To Len(_aTLinhas)
	
    If oProc <> NIL
	   oProc:cCaption := ("Enviando Log: "+AllTrim(StrZero(_nI,_nTam))+" de "+ _cTot)
	   ProcessMessages()
	EndIf   
	
	_cOKLista += '    <tr>'
	_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[01]+'%">'+ _aTLinhas[_nI][01]+'</td>'
	_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[02]+'%">'+ _aTLinhas[_nI][02]+'</td>'
	_cOKLista += '      <td class="itens" align="center" width="'+_aSizeOK[03]+'%">'+ _aTLinhas[_nI][03]+'</td>'
	_cOKLista += '      <td class="itens" align="right"  width="'+_aSizeOK[04]+'%">'+ _aTLinhas[_nI][04]+'</td>'
	_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%">SALDO NEGATIVO</td>'
	_cOKLista += '    </tr>'
	_lEnvia:=.T.

Next

If _lEnvia
   _cMsgEml:=StrTran(_cMsgEml,"#LISTAOK#",_cOKLista)  

   // Chama a função para envio do e-mail
   U_ITENVMAIL( "", cGetPara, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
		           "E-mail para: "+cGetPara+;
		           " Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)
   EndIf
Else   
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      U_ITMsg("Não tem registros para enviar","Envio do E-MAIL",,1)
   EndIf   
EndIf

Return .T.
