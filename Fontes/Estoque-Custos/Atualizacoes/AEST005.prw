/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |22/03/2018| Chamado 24257. Ajustes no tratamento dos niveis para o grupo "0599". 
Alex Wallauer |18/10/2022| Chamado 41596. Permitir a edição do campo B1_COD e não gerar o codigo automatico.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: AEST005
Autor-------------: Cleiton Campos 
Data da Criacao---: 15/07/2008
Descrição---------: Gerar o campo B1_COD de forma automatica - Gatilho := B1_GRUPO  001
Parametros--------: _pcGrupo = Grupo de produtos
Retorno-----------: _cRetorno = Retorna codigo para cadastro de produtos
                    Se B1_TIPO <> 'PA' : Sendo o codigo do produto composto do grupo mais um numero sequencial de 7 digitos.
                    Se B1_TIPO == 'PA' ou B1_TIPO == 'EM' : Mantem codigo atual do produto
===============================================================================================================================
*/
User Function AEST005(_pcGrupo)
Local _aArea    := FWGetArea()
Local _cRetorno := ""          
Local _cQuery   := ""
Local _oModel	 := FWModelActive()
Local _oModelSB1:= _oModel:GetModel('SB1MASTER')

M->B1_I_NIV2 :=Space(003)
M->B1_I_DESN2:=Space(040)
M->B1_I_NIV3 :=Space(002)
M->B1_I_DESN3:=Space(030)
M->B1_I_NIV4 :=Space(002)
M->B1_I_DESN4:=Space(030)
M->B1_DESC   :=Space(100)
M->B1_I_DESCD:=Space(100)

_oModelSB1:LoadValue('B1_I_NIV2' ,M->B1_I_NIV2 )
_oModelSB1:LoadValue('B1_I_DESN2',M->B1_I_DESN2)
_oModelSB1:LoadValue('B1_I_NIV3' ,M->B1_I_NIV3 )
_oModelSB1:LoadValue('B1_I_DESN3',M->B1_I_DESN3)
_oModelSB1:LoadValue('B1_I_NIV4' ,M->B1_I_NIV4 )
_oModelSB1:LoadValue('B1_I_DESN4',M->B1_I_DESN4)
_oModelSB1:LoadValue('B1_DESC'   ,M->B1_DESC   )
_oModelSB1:LoadValue('B1_I_DESCD',M->B1_I_DESCD)
	
If (AllTrim(M->B1_TIPO) $ "PA/EM" .And. !(M->B1_TIPO = "EM" .And. M->B1_GRUPO = "0599")) .Or. M->B1_TIPO = "MO"//Não calcula o codigo PARA essas condiçoes
   Return (M->B1_COD)
EndIf     
	
_cQuery := " SELECT MAX(B1_COD) AS CODIGO "
_cQuery += " FROM " + RetSqlName("SB1")
_cQuery += " WHERE D_E_L_E_T_ <> '*'"
_cQuery += " AND   B1_GRUPO = '" + AllTrim(_pcGrupo) + "' "

TcQuery _cQuery New Alias "QRY"

DBSelectArea("QRY")
DBGoTop()

_cRetorno := AllTrim(_pcGrupo)+StrZero(Val(Right(AllTrim(QRY->CODIGO),7))+1,7)

While !MayIUseCode( "B1_COD"+xFilial("SB1")+_cRetorno)  //verifica se esta na memoria, sendo usado
	_cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
EndDo

DBSelectArea("QRY")
DBCloseArea()

FWRestArea(_aArea)

Return(_cRetorno)
