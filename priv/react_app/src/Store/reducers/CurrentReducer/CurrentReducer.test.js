/*
*   This file tests the reducers handling incoming actions.
*   See http://redux.js.org/docs/recipes/WritingTests.html for writing action and reducer tests.
*/
import {Actions, actionTypes} from './../../../Store'
import reducer from './CurrentReducer'

describe('Current reducer', () => {
	it('should return the empty initial state', () => {
    const initialState = {
      user: undefined
    }
		expect(reducer(undefined, {})).toEqual(initialState)
  })

  it("should handle current user", () => {
    const testUser = { id: 1, name: 'Test User' }
    const state = reducer(undefined, Actions.users.getCurrentUserSuccess(testUser))
    expect(state).toMatchObject({user: testUser.id})
  })

})
