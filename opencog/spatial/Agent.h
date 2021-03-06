/*
 * opencog/spatial/Agent.h
 *
 * Copyright (C) 2002-2009 Novamente LLC
 * All Rights Reserved
 * Author(s): Samir Araujo
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3 as
 * published by the Free Software Foundation and including the exceptions
 * at http://opencog.org/wiki/Licenses
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program; if not, write to:
 * Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef _SPATIAL_AGENT_H_
#define _SPATIAL_AGENT_H_

#include <opencog/spatial/MovableEntity.h>

namespace opencog
{
/** \addtogroup grp_spatial
 *  @{
 */
    namespace spatial
    {

        class Agent;
        typedef boost::shared_ptr<Agent> AgentPtr;

        class Agent : public MovableEntity
        {
        public:

            inline Agent( const Agent& agent ) : 
                MovableEntity( agent.id, agent.name, agent.position, 
                    agent.dimension, agent.orientation, agent.expansionRadius ) 
            {
            }

            inline Agent( long id, const std::string& name, const math::Vector3& position, 
                const math::Dimension3& dimension, const math::Quaternion& orientation, 
                    double radius = 0.0 ) : 
                        MovableEntity( id, name, position, dimension, orientation, radius ) 
            {
            }

            /**
             * Get a point that indicate the position of the agent's eye
             * @return
             */
            inline math::Vector3 getEyePosition( void ) 
            {
                return this->getPosition() + ( getDirection( ) * ( this->getLength() / 2 ) )
                    + ( math::Vector3::Y_UNIT * (this->getHeight() / 2) );
            }

            virtual ENTITY_TYPE getType( void ) const = 0;

            virtual EntityPtr clone( void ) const = 0;


        }; // Agent

    } // spatial
} // opencog

#endif // _SPATIAL_AGENT_H_
