
#Include "TOTVS.ch"

Static __cUsuario  := "" As Character 
Static __cIDAcesso := "" As Character

/*
===============================================================================================================================
Programa----------: PCMNLOGO
Autor-------------: Igor Melgaço
Data da Criacao---: 22/08/2025
Descrição---------: Ponto de Entrada de customização do logo do menu do Protheus.
                   Este ponto de entrada é utilizado para customizar o logo do menu do Protheus, 
                   permitindo a personalização da imagem exibida no menu principal.
                   Ele recebe um JSON com as propriedades esperadas e o código do usuário logado no portal.
                   Dependendo do usuário, o logo exibido pode ser diferente.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function PCMNLOGO() As Json

Local jCustom  := ParamIXB[1] as Json //Json com as propriedades esperadas.
Local _cHostWF := SuperGetMv("IT_LOGOPC",.F.,"\data\italac\logos") As Character   
Local _cLogo   := _cHostWF + "\logo_novo.jpg" As Character 

__cUsuario   := ParamIXB[2] 
__cIDAcesso := ""

//Customizações de menu
If jCustom:hasProperty('logo')
    jCustom['logo'] := _cLogo
EndIf
If jCustom:hasProperty('shortLogo')
    jCustom['shortLogo'] := _cLogo
EndIf
If jCustom:hasProperty('logoText')
    jCustom['logoText'] := 'Italac'
EndIf

U_ITGrvAce("LOGIN")

Return jCustom


User Function ITGrvAce(_cPonto As Character,_cDetalhe As Character)
Local _cQuery   := "" As Char
Local _cAlias   := GetNextAlias() As Character

Default _cDetalhe := "" 

If _cPonto == "LOGIN"
	
	_cQuery := " SELECT MAX(Z16_IDACES) AS ID "
	_cQuery += " FROM " + RetSqlName("Z16")
	_cQuery += " WHERE D_E_L_E_T_ <> '*'"
	_cQuery += " AND Z16_ROTINA = 'PORTAL CLIENTE' "

	_cQuery := ChangeQuery(_cQuery)

	MPSysOpenQuery(_cQuery,_cAlias)

	DbSelectArea(_cAlias)
	DbGoTop()

	__cIDAcesso := StrZero(Val(Right(Alltrim((_cAlias)->ID),10))+1,10)

	Do While !MayIUseCode( "Z16_CONTA"+__cIDAcesso)  //verifica se esta na memoria, sendo usado
		__cIDAcesso := Soma1(__cIDAcesso)				 // busca o proximo numero disponivel
	EndDo

	DbSelectArea(_cAlias)
	DbCloseArea()

EndIf

Z16->(RecLock('Z16',.T.))
Z16->Z16_ROTINA		:= "PORTAL CLIENTE"
Z16->Z16_PONTO		:= _cPonto
Z16->Z16_DATA		:= Date()
Z16->Z16_HORA		:= Time()
Z16->Z16_DETALH     := _cDetalhe
Z16->Z16_IDACES		:= __cIDAcesso
Z16->Z16_LOGIN		:= __cUsuario
Z16->( MSUnLock() )

Return
