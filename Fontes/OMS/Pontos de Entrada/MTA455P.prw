#Include "RwMake.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: MTA455P
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 11/08/2009
===============================================================================================================================
Descrição---------: Ponto de Entrada para validar Liberacao Manual do Estoque
===============================================================================================================================
Uso---------------: Italac - Valida a permissao para liberacao manual do Estoque de Produto Acabado para Venda no modulo OMS
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico - Definindo se pode liberar
===============================================================================================================================
Usuario-----------: 
===============================================================================================================================
Setor-------------: OMS
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                              Motivo                       |        Usuario         |  Setor  |
-------------------------------------------------------------------------------------------------------------------------------
 Guilherme Diogo  | 27/11/2012 | Alterado PswSeek, pois na versão 11 é preciso posicionar  | 90-000285-GUILHERMED   |  TI-SP  |
                  |            | pelo ID ou nome do usuário para depois verificar a senha  |                        |         |
------------------:------------:-----------------------------------------------------------:------------------------:---------:
 Talita           | 17/07/2013 | Alterada a validação na liberação do estoque para que seja| 92-000300-TALITAT      |  TI-SP  |
                  |            | feita pelo cadastro da Gestão de Usuários. Chamado 3748   |                        |         |
------------------:------------:-----------------------------------------------------------:------------------------:---------:
 Alexandre Villar | 30/09/2014 | Atualização da rotina retirando comentários e referências | 01-003485-ALEXANDREV   |  TI-CB  |
                  |            | ao parâmetro que não está mais em uso. Retirada também a  |                        |         |
                  |            | opção para digitação de senha, validando apenas a config. |                        |         |
                  |            | do usuário para o acesso. Chamado 7249                    |                        |         |
===============================================================================================================================
*/

User Function MTA455P()
    
Local _aArea 	:= FWGetArea()
Local _lRet		:= .F.
Local _cUsuLog	:= RetCodUsr()

//================================================================================
// Talita - 16/07/13 - Alterada a validação na liberação do estoque para que era 
// feito pelo parametro IT_LIBEST e agora será feita na tela de gestão de usuarios
// campo ZZL_LIBEST. Chamado:3748
//================================================================================
// Removida a configuração de digitação de senha para liberação manual do estoque,
// será feita a validação apenas pelo controle de acesso da Gestão de Usuários.
// Alexandre Villar - Chamado 7249
//================================================================================
DBSelectArea("ZZL")
ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + _cUsuLog ) ) .And. ZZL->ZZL_LIBEST == 'S'

	_lRet := .T.

Else

	Aviso( 'Atenção!' , 'O usuário atual não possui acesso para realizar a liberação manual de Estoque! '									+;
						'Caso necessário, solicite ao usuário responsável por essa atividade para que realize a liberação.'	, {'Fechar'} , 2 )

EndIf

FWRestArea( _aArea )

Return( _lRet )
