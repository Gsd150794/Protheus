/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |24/09/2015| Chamado 11950. Ajuste geral da rotina para implantação de processo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT107FIL
Autor-----------: Andre Lisboa
Data da Criacao-: 24/08/2015
Descrição-------: P.E. para filtrar Mbrowse rotina MATA107
Parametros------: Nenhum
Retorno---------: _cFiltro - string de filtro para mbrowse
===============================================================================================================================
*/
User Function MT107FIL()

Local  _cFiltro 		:= "CP_STATSA = 'Z'"
Local  _cUser			:= RetCodUsr()
Local  _cGrpApr		:= ""
Local  _aArea			:= FWGetArea()

//Lê grupo de aprovação do usuário Italac
_cGrpApr := AllTrim(Posicione("ZZL",3,xFilial("ZZL")+_cUser,"ZZL->ZZL_GRPAPR"))

//Se o grupo de aprovação For válido e não For o grupo geral, faz o filtro pelo grupo de aprovação
If _cGrpApr <> "0" .And. !(Empty(_cGrpApr))

	_cFiltro := "CP_I_GRAPR == '" + _cGrpApr + "' .And. CP_STATSA = 'B'"

//Se o grupo de aprovação For o geral então apresenta tudo que está bloqueado
ElseIf _cGrpApr == "0"

	_cFiltro := "CP_STATSA = 'B'"

EndIf

FWRestArea(_Aarea)

Return (_cFiltro)
