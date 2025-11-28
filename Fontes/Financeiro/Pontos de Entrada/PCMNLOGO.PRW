/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |22/09/2025| Chamado 51754. Ponto de Entrada de customização do logo do menu do Protheus.
===============================================================================================================================
*/

#Include "TOTVS.ch"

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

Return jCustom
