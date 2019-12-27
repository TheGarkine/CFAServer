cmake_minimum_required( VERSION 3.3 )

project( ACM_SIGCONF NONE )

include( cmake/UseLATEX.cmake )

set( BIBTEX_COMPILER bibtex )

file( GLOB CODE_SAMPLES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
      "code/*.c"
      "code/*.cpp"
      "code/*.h"
      "code/*.js"
      "code/*.cs"
      "code/*.java"
      "code/*.py" )

file( GLOB CONTENT_SRC RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
      "content/*.tex" )

add_latex_document( sample-sigconf.tex
                    INPUTS ${CODE_SAMPLES} ${CONTENT_SRC}
                    BIBFILES bibliography.bib
                    IMAGE_DIRS img
                    FORCE_PDF )
