/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |13/12/2018| Chamado 27244. Ajuste de variáveis e performance
Josué Danich  |23/01/2019| Chamado 27495. Retirada de pergunte redundante 
Igor Melgaço  |06/05/2022| Chamado 39987. Substituição do E1_EMISSAO pelo E1_EMIS1 na query
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FA330QRY
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/11/2017
Descrição---------: Ponto de entrada de filtro do browse da tela de compensação - Chamado 22322
Parametros--------: Nenhum
Retorno-----------: ParamIXB[1] - filtro sql
===============================================================================================================================
*/
User Function FA330QRY()

Local _cini := " " 
Local _cfim := " " 
Local _cfil := " "

//Testa para ver se ParamIXB veio com query 
If Type("ParamIXB[1]") == "C"

	If "ORDER BY" $ ParamIXB[1]

		_cini := left(ParamIXB[1],at("ORDER BY",ParamIXB[1])-1)
		_cfim := right(ParamIXB[1],(Len(ParamIXB[1])+1-at("ORDER BY",ParamIXB[1])))
		
	Else
	
		_cini := ParamIXB[1]
		_cfim := ""
		
	EndIf
	
Else

	U_ITMsg("Falha de localização de títulos","Atenção","Contate o TI - Filial " + SE1->E1_FILIAL + " - Titulo " + SE1->E1_NUM ,1)
	
	Return 

EndIf

//Retesta MV_PAR para garantir que foram carregados corretamente
If Type("MV_PAR18") == "D" .And. Type("MV_PAR16") == "C" .And. Type("MV_PAR17") == "N"
   
    
	If !(MV_PAR18 > SToD('20010101'))

		MV_PAR18 := SToD('20010101')
	
	EndIf

	If !Empty(MV_PAR16)

		_cfil += " AND SE1.E1_TIPO = '" + AllTrim(MV_PAR16) + "' "
  
	EndIf

	If MV_PAR17 == 2

		_cfil += " AND SE1.E1_NUM = '" + AllTrim(SE1->E1_NUM) + "' " 
  
	EndIf
	
	//ParamIXB[1] := _cini + _cfil + " AND SE1.E1_EMISSAO > '" + DToS(MV_PAR18) + "' " + _cfim
	ParamIXB[1] := _cini + _cfil + " AND SE1.E1_EMIS1 > '" + DToS(MV_PAR18) + "' " + _cfim
	
Else

	//Se falhou carga de parametros manda filtro restrito para não ter demora no processamento

	U_ITMsg("Falha de leitura de parâmetros, carregando somente título com mesmo número","Atenção","Entre no F12 para carregar parâmetros",1)

	_cfil += " AND SE1.E1_NUM = '" + AllTrim(SE1->E1_NUM) + "' " 
	ParamIXB[1] := _cini + _cfil + _cfim

EndIf



Return ParamIXB[1]
