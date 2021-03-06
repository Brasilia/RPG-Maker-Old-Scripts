#==============================================================================#
# Lehanius Dynamic Troops
#------------------------------------------------------------------------------#
# Autor: Lehanius
#
# Versão: VXA 1.2 BR
# Data: d/m 17/01/2012
#
# Contatos:
# - http://www.santuariorpgmaker.com/forum/index.php?action=profile;u=80
# - rafael_1247@hotmail.com
#
#==============================================================================#
#
#==============================================================================#
# Termos de Uso - Terms of Use
#------------------------------------------------------------------------------#
#   - IMPORTANTE:                                                      
#   * Este script pode ser utilizado livremente para projetos pessoais,
# porém peço os devidos créditos ao autor.
#   * Se modificado, este script não deve ser distribuído sem que se
# explicite que ele foi alterado.
#   * Não remova nem altere os comentários do cabeçalho deste script,
# mesmo se o código for alterado. Quando for esse o caso, indique a
# alteração abaixo destes comentários.
#   * Se encontrar algum bug, por favor me informe por um dos contatos acima.                                                        
#                                                                      
#   - NOTICE:                                                          
#   * This script may be used for private projects, though the author  
# should be credited properly.                                         
#   * If you wish to modify and distribute this script, please make    
#  sure to inform that it has been modified.                           
#   * Do not remove or change the contents of these header comments.   
# If you have modified the script, please state it below this header.  
#   * If you find any bugs, please contact me by email or by the forum.
#==============================================================================#

=begin
#==============================================================================#
# Descrição
#------------------------------------------------------------------------------#
    Este sistema permite que se monte cada grupo inimigo de batalha em tempo 
  real, ou seja: a tropa inimiga não precisa estar configurada no database.
  
    Os inimigos podem ser especificados por sua ID ou por uma variável.
    
    Além disso, o sistema oferece suporte a batalhas iniciadas por eventos de 
  mapa - inimigos no mapa - iniciando a batalha com um grupo que inclui cada um
  dos inimigos que foi iniciado durante um período determinado.
#==============================================================================#
#
#==============================================================================#
# Instruções
#------------------------------------------------------------------------------#
  - Defina a tropa do database que será utilizada como máscara para indicar as 
  posições de cada inimigo na batalha: TROOP_ID
  
  - No database, em tropas, insira os inimigos (preferencialmente 8, de qualquer
  tipo) nas posições em que quer que cada inimigo apareça. Lembre-se de que a 
  ordem em que você insere cada inimigo importa para a posição que ele ocupará, 
  então pode ser interessante usar inimigos diferentes para a configuração, 
  apenas para lembrar quem foi inserido antes ou depois.
  
  - Para iniciar uma batalha com tropas dinâmicas, basta criar um comentário em
  um evento da seguinte forma:
      <>Comentário:ENEMY <delay(opcional)>
                  :<inimigo 1>
                  :<inimigo 2>
                  :<inimigo 3>
                  :<...>
      Em que:
          <delay> é o tempo de espera até que a batalha seja iniciada; isso 
        serve para que se possa "coletar" mais inimigos para a batalha até que 
        ela comece. Se esse campo não for inserido no comentário, será usado o 
        valor padrão de atraso, definido por BATTLE_DELAY.
          <inimigo> pode ser tanto a ID do inimigo inserido na batalha como uma
        variável que contenha essa ID. Se for inserido apenas um número, ele 
        será a ID; se desejar usar uma variável para especificar o inimigo, use
        "V[n]" na linha de comentário, sem aspas, em que "n" é a ID da variável.
        
  - Se desejar usar uma outra tropa como base para a batalha seguinte, antes da
  chamada de combate use este comando de chamar script, com o id da tropa:
  <>Script: $game_temp.ldt_change_troop(<id>)
#==============================================================================#
=end

#==============================================================================#
# + Config - Edite estes valores para configurar o sistema
#------------------------------------------------------------------------------#
module LDT
  # ID da tropa a ser utilizada como modelo de posição em batalha
  TROOP_ID = 31
  # Tempo de espera padrão para o início da batalha, desde sua primeira chamada
  BATTLE_DELAY = 60 # frames
end
#------------------------------------------------------------------------------#
# END Config
#==============================================================================#
#==============================================================================#
# Game_Temp - gerencia as variáveis globais do sistema
#------------------------------------------------------------------------------#
class Game_Temp
  attr_accessor :ldt_troop
  attr_accessor :ldt_index
  attr_accessor :ldt_troop_id
  attr_accessor :ldt_battle_join
  attr_accessor :battle_closed
  alias ldt_initialize initialize
  def initialize
    ldt_initialize
    @ldt_troop_id = LDT::TROOP_ID
    @ldt_troop = $data_troops[@ldt_troop_id]
    ldt_refresh
  end
  def ldt_refresh
    @ldt_index = 0
    @battle_closed = false
  end
  def ldt_change_troop(id)
    id = LDT::TROOP_ID if id < 1
    @ldt_troop_id = id
    @ldt_troop = $data_troops[@ldt_troop_id]
  end
end
#------------------------------------------------------------------------------#
# END Game_Temp
#==============================================================================#
#==============================================================================#
# Game_Interpreter
#------------------------------------------------------------------------------#
class Game_Interpreter 
  #--------------------------------------------------------------------------
  # * Processamento da batalha - correção de batalhas simultâneas
  #--------------------------------------------------------------------------
  alias ldt_command_301 command_301
  def command_301
    return if SceneManager.scene_is?(Scene_Battle)
    ldt_command_301
  end
  #--------------------------------------------------------------------------
  # * Comentários - monta o grupo de batalha
  #--------------------------------------------------------------------------
  alias ldt_command_108 command_108
  def command_108
    ldt_command_108
    # Case enemy engages
    if @comments[0].split[0] == "ENEMY" && !$game_temp.battle_closed
      battle_out = $game_temp.ldt_battle_join
      $game_temp.ldt_refresh unless battle_out
      $game_temp.ldt_battle_join = true
      delay = @comments[0].split[1] ? @comments[0].split[1].to_i : LDT::BATTLE_DELAY
      @comments.delete_at(0)
      #Add Troop Members Loop
      for member in @comments
        if member.delete! "V["
          member.delete "]"
          member = $game_variables[member.to_i]
        end
        $game_temp.ldt_troop.members[$game_temp.ldt_index].enemy_id = member.to_i
        $game_temp.ldt_index += 1
      end
      wait(delay)
      @params = [0, $game_temp.ldt_troop_id, false, false]
      $game_temp.battle_closed = true if !battle_out
      return if battle_out
      $game_temp.ldt_battle_join = false
      command_301
      $game_temp.ldt_change_troop(LDT::TROOP_ID) #resets do default troop
      $game_temp.battle_closed = false
      wait(10)
    end
  end
end
#------------------------------------------------------------------------------#
# END Game_Interpreter
#==============================================================================#
#==============================================================================#
# Game_Troop
#------------------------------------------------------------------------------#
class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # * Configuração do grupo de inimigos
  #     troop_id : ID do grupo de inimigos
  #   - No LDT, inclui apenas os inimigos adicionados à batalha
  #--------------------------------------------------------------------------
  def setup(troop_id)
    clear
    @troop_id = troop_id
    @enemies = []
    index = 0
    troop.members.each do |member|
      if $game_temp.ldt_index > 0
        member = $game_temp.ldt_troop.members[index]
        index += 1
      end
      next unless $data_enemies[member.enemy_id]
      enemy = Game_Enemy.new(@enemies.size, member.enemy_id)
      enemy.hide if member.hidden
      enemy.screen_x = member.x
      enemy.screen_y = member.y
      @enemies.push(enemy)
      break if index == $game_temp.ldt_index && index != 0
    end
    init_screen_tone
    make_unique_names
  end
end
#------------------------------------------------------------------------------#
# END Game_Troop
#==============================================================================#
