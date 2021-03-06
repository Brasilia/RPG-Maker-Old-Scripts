
#==============================================================================#
# Fix Party Member VXA.2.2
#------------------------------------------------------------------------------#
# Autor: Lehanius
# Colaboraçao: Victor_Sant
#
# Data: d.m. 04/01/2012
#
# Contatos:
# - http://www.santuariorpgmaker.com/forum/index.php?action=profile;u=80
# - rafael_1247@hotmail.com
#
#==============================================================================#

#==============================================================================#
# Descrição
#------------------------------------------------------------------------------#
# - Permite que se mantenha determinados membros do grupo fixos na formação, 
# ou seja: o jogador não poderá trocá-los por outros membros.
# - O script permite que, durante o jogo, essa lista de personagens fixos seja 
# modificada, por meio dos comandos $game_actors[id].fixed = <true/false>, 
# que podem ser chamados por eventos, pelo comando de Chamar Script
#==============================================================================#

#==============================================================================#
# Config
#------------------------------------------------------------------------------#
#   - Comandos de Script:
# - $game_actors[id].fixed = true:  fixa o ator com essa id
# - $game_actors[id].fixed = false: desfixa o ator com essa id
#==============================================================================#
module LFPM
  #--------------------------------------------------------------------------
  # Armazena os índices dos atores inicialmente fixos (a id é a do database)
  # Defina seu valor inicial (pode ser "[]")
  #--------------------------------------------------------------------------
  INIT_FIXED_ACTORS = [7]
end
#------------------------------------------------------------------------------#
# END Config
#==============================================================================#
#==============================================================================#
# Game_Actor
# - Armazena o valor de @fixed, que pode ser true ou false
#------------------------------------------------------------------------------#
class Game_Actor < Game_Battler
  attr_accessor :fixed
  alias lfpm_setup setup
  def setup(actor_id)
    lfpm_setup(actor_id)
    @fixed = LFPM::INIT_FIXED_ACTORS.include?(actor_id)
  end
end
#------------------------------------------------------------------------------#
# END Game_Actor
#==============================================================================#
#==============================================================================#
# Scene_Menu
# - Indica à @status_window se o comando ativo é o de formação
#------------------------------------------------------------------------------#
class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # Entrada no comando de formação
  #--------------------------------------------------------------------------
  alias lfpm_command_formation command_formation
  def command_formation
    @status_window.formation_running = true
    lfpm_command_formation
  end
  #--------------------------------------------------------------------------
  # Fora do comando de formação
  #--------------------------------------------------------------------------
  alias lfpm_command_personal command_personal
  def command_personal
    @status_window.formation_running = false
    lfpm_command_personal
  end
end
#------------------------------------------------------------------------------#
# END Scene_Menu
#==============================================================================#
#==============================================================================#
# Window_MenuStatus
# - Verifica se o ator atual está fixo e se o comando ativo é o de formação
#------------------------------------------------------------------------------#
class Window_MenuStatus < Window_Selectable
  #--------------------------------------------------------------------------
  # Modifica a indicação de execução do comando de formação
  #--------------------------------------------------------------------------
  attr_accessor :formation_running
  #--------------------------------------------------------------------------
  # Desabilita o ator selecionado se ele estiver fixo
  #--------------------------------------------------------------------------
  def current_item_enabled?
    !($game_party.members[@index].fixed && formation_running)
  end
end
#------------------------------------------------------------------------------#
# END Window_MenuStatus
#==============================================================================#
