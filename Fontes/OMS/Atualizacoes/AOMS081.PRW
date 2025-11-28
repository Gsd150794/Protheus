/*
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===========================================================================================================================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
===========================================================================================================================================================================================================================================================
Vandelei - Alex Wallauer - 10/10/25 - 13/10/25 -  52438  - Colocado o botão de "Monitor Integração" na rotina de ocorrências de frete chamando essa função
.===========================================================================================================================================================================================================================================================*/
#Include "TOTVS.ch"
/*
===============================================================================================================================
Programa----------: AOMS081
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/10/2016
Descrição---------: Rotina de consulta da integração e recebimento de dados Ocorrências de Frete via webservice para empresa RDC.
===============================================================================================================================
*/
User Function AOMS081()
 Local _aCores    := {} As Array
 Private aRotina  := {} As Array
 Private cCadastro:= "Integração dos Dados dos Ocorrências de Frete Via Webservice: RDC -> Italac" As Char

 AAdd(aRotina,{"Pesquisar" ,"AxPesqui"  ,0,1})
 AAdd(aRotina,{"Visualizar","AxVisual"  ,0,2})
 AAdd(aRotina,{"Legenda"   ,"U_AOMS081L",0,1})

 AAdd(_aCores,{"ZFO_SITUAC == 'P'" ,"BR_VERDE"   })
 AAdd(_aCores,{"ZFO_SITUAC == 'R'" ,"BR_VERMELHO"})

 ZFO->(DBSetOrder(1))
 ZFO->(DBGoTop())
 MBrowse(6,1,22,75,"ZFO", , , , , , _aCores)

 Return

/*
===============================================================================================================================
Programa----------: AOMS081L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
===============================================================================================================================
*/
User Function AOMS081L()
 Local _aLegenda := {} As Array

 AAdd(_aLegenda,{"BR_VERDE"    ,"Aceito" })
 AAdd(_aLegenda,{"BR_VERMELHO" ,"Rejeitado" })

 BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return


